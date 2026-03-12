#!/usr/bin/env node

import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { parse as parseJsonc } from 'jsonc-parser';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import * as z from 'zod/v4';

function isRepoRoot(candidate) {
  return existsSync(path.join(candidate, '.vscode', 'tasks.json')) && existsSync(path.join(candidate, '.vscode', 'settings.json'));
}

function resolveRepoRoot() {
  const scriptDir = path.dirname(fileURLToPath(import.meta.url));
  const candidateRoots = [
    process.env.COFFEE_MCP_REPO_ROOT,
    process.cwd(),
    path.resolve(scriptDir, '..', '..')
  ].filter(Boolean).map(candidate => path.resolve(candidate));

  for (const candidate of candidateRoots) {
    if (isRepoRoot(candidate)) {
      return candidate;
    }
  }

  throw new Error('Unable to resolve repository root for coffee-tools MCP server.');
}

const repoRoot = resolveRepoRoot();
const settingsPath = path.join(repoRoot, '.vscode', 'settings.json');
const tasksPath = path.join(repoRoot, '.vscode', 'tasks.json');
const instructionsPath = path.join(repoRoot, '.github', 'copilot-instructions.md');
const maxOutputBytes = 40_000;
const maxTimeoutSeconds = 900;

function parseJsonFile(contents, fallback) {
  try {
    return parseJsonc(contents);
  } catch {
    return fallback;
  }
}

function trimOutput(text) {
  if (text.length <= maxOutputBytes) {
    return { text, truncated: false };
  }

  return {
    text: `${text.slice(0, maxOutputBytes)}\n\n[output truncated]`,
    truncated: true
  };
}

function formatCommand(command, args = []) {
  return [command, ...args].join(' ').trim();
}

function ruleMatches(rule, fullCommand) {
  if (rule.kind === 'regex') {
    return rule.pattern.test(fullCommand);
  }

  return fullCommand === rule.pattern || fullCommand.startsWith(`${rule.pattern} `);
}

function parseRule(pattern, allowed) {
  if (pattern.startsWith('/') && pattern.endsWith('/')) {
    return {
      kind: 'regex',
      pattern: new RegExp(pattern.slice(1, -1)),
      allowed,
      source: pattern
    };
  }

  return {
    kind: 'literal',
    pattern,
    allowed,
    source: pattern
  };
}

async function loadCommandPolicy() {
  const rawSettings = await fs.readFile(settingsPath, 'utf8');
  const settings = parseJsonFile(rawSettings, {});
  const approvals = settings['chat.tools.terminal.autoApprove'] || {};

  return Object.entries(approvals).map(([pattern, allowed]) => parseRule(pattern, Boolean(allowed)));
}

async function loadTasks() {
  const rawTasks = await fs.readFile(tasksPath, 'utf8');
  const config = parseJsonFile(rawTasks, { tasks: [] });

  return (config.tasks || [])
    .filter(task => task.type === 'shell' && typeof task.label === 'string' && typeof task.command === 'string')
    .map(task => ({
      label: task.label,
      command: task.command,
      isBackground: Boolean(task.isBackground)
    }));
}

function assertSafeInput(command, args, cwd) {
  const values = [command, cwd, ...args].filter(Boolean);

  for (const value of values) {
    if (typeof value !== 'string') {
      throw new Error('Commands, args, and cwd must be strings.');
    }

    if (value.includes('\n') || value.includes('\r')) {
      throw new Error('Newlines are not allowed in command input.');
    }
  }
}

function resolveWorkingDirectory(cwd = '.') {
  const resolved = path.resolve(repoRoot, cwd);

  if (resolved !== repoRoot && !resolved.startsWith(`${repoRoot}${path.sep}`)) {
    throw new Error('Working directory must stay inside the repository.');
  }

  return resolved;
}

async function executeCommand({ command, args = [], cwd = '.', timeoutSeconds = 120 }) {
  assertSafeInput(command, args, cwd);

  const policy = await loadCommandPolicy();
  const fullCommand = formatCommand(command, args);
  const deniedBy = policy.find(rule => !rule.allowed && ruleMatches(rule, fullCommand));

  if (deniedBy) {
    throw new Error(`Command denied by policy: ${deniedBy.source}`);
  }

  const allowedBy = policy.find(rule => rule.allowed && ruleMatches(rule, fullCommand));

  if (!allowedBy) {
    throw new Error('Command is not approved by .vscode/settings.json chat.tools.terminal.autoApprove.');
  }

  const normalizedTimeout = Math.max(1, Math.min(timeoutSeconds, maxTimeoutSeconds));
  const resolvedCwd = resolveWorkingDirectory(cwd);

  return await new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd: resolvedCwd,
      env: process.env,
      shell: false,
      stdio: ['ignore', 'pipe', 'pipe']
    });

    let stdout = '';
    let stderr = '';
    let timedOut = false;

    const timer = setTimeout(() => {
      timedOut = true;
      child.kill('SIGTERM');
      setTimeout(() => child.kill('SIGKILL'), 2_000).unref();
    }, normalizedTimeout * 1_000);

    child.stdout.on('data', chunk => {
      stdout += chunk.toString('utf8');
    });

    child.stderr.on('data', chunk => {
      stderr += chunk.toString('utf8');
    });

    child.on('error', error => {
      clearTimeout(timer);
      reject(error);
    });

    child.on('close', code => {
      clearTimeout(timer);

      const trimmedStdout = trimOutput(stdout);
      const trimmedStderr = trimOutput(stderr);

      resolve({
        command: fullCommand,
        cwd: path.relative(repoRoot, resolvedCwd) || '.',
        exitCode: code ?? -1,
        timedOut,
        stdout: trimmedStdout.text,
        stderr: trimmedStderr.text,
        stdoutTruncated: trimmedStdout.truncated,
        stderrTruncated: trimmedStderr.truncated,
        allowedBy: allowedBy.source
      });
    });
  });
}

function ensureRepoRelativePath(filePath) {
  const resolved = resolveWorkingDirectory(filePath);
  return path.relative(repoRoot, resolved) || '.';
}

function filterNonEmptyLines(text) {
  return text
    .split('\n')
    .map(line => line.trimEnd())
    .filter(Boolean);
}

function selectRouteLines(output, filter) {
  const lines = filterNonEmptyLines(output);

  if (!filter) {
    return lines;
  }

  const normalizedFilter = filter.toLowerCase();
  return lines.filter(line => line.toLowerCase().includes(normalizedFilter));
}

async function runFocusedRspec({ specPath, line, example, timeoutSeconds }) {
  const repoRelativePath = ensureRepoRelativePath(specPath);
  const target = line ? `${repoRelativePath}:${line}` : repoRelativePath;
  const args = [target];

  if (example) {
    args.push('--example', example);
  }

  return await executeCommand({
    command: 'bin/rspec',
    args,
    timeoutSeconds
  });
}

async function runQualitySuite({ timeoutSeconds }) {
  const steps = [
    { name: 'rubocop', command: 'bin/rubocop', timeoutSeconds: Math.min(timeoutSeconds, 300) },
    { name: 'brakeman', command: 'bin/brakeman', timeoutSeconds: Math.min(timeoutSeconds, 300) },
    { name: 'rspec', command: 'bin/rspec', timeoutSeconds }
  ];

  const results = [];

  for (const step of steps) {
    const result = await executeCommand({
      command: step.command,
      timeoutSeconds: step.timeoutSeconds
    });

    results.push({
      name: step.name,
      ...result
    });

    if (result.exitCode !== 0 || result.timedOut) {
      break;
    }
  }

  return {
    ok: results.every(result => result.exitCode === 0 && !result.timedOut),
    results
  };
}

function toTextResult(value) {
  return {
    content: [
      {
        type: 'text',
        text: typeof value === 'string' ? value : JSON.stringify(value, null, 2)
      }
    ]
  };
}

const server = new McpServer(
  {
    name: 'coffee-tools',
    version: '1.0.0'
  },
  {
    capabilities: {
      logging: {}
    }
  }
);

server.registerTool(
  'list_command_policy',
  {
    title: 'List Command Policy',
    description: 'Show which terminal commands this Coffee repo MCP server will allow or deny, based on .vscode/settings.json.',
    inputSchema: z.object({})
  },
  async () => {
    const policy = await loadCommandPolicy();

    return toTextResult({
      repoRoot,
      allowed: policy.filter(rule => rule.allowed).map(rule => rule.source),
      denied: policy.filter(rule => !rule.allowed).map(rule => rule.source)
    });
  }
);

server.registerTool(
  'list_repo_tasks',
  {
    title: 'List Repo Tasks',
    description: 'List shell tasks defined in .vscode/tasks.json, including whether they are background tasks.',
    inputSchema: z.object({})
  },
  async () => {
    const tasks = await loadTasks();
    return toTextResult(tasks);
  }
);

server.registerTool(
  'run_repo_task',
  {
    title: 'Run Repo Task',
    description: 'Run a non-background shell task from .vscode/tasks.json when its command is allowed by the repo command policy.',
    inputSchema: z.object({
      label: z.string().describe('Exact VS Code task label from .vscode/tasks.json'),
      timeoutSeconds: z.number().int().min(1).max(maxTimeoutSeconds).default(120)
    })
  },
  async ({ label, timeoutSeconds }) => {
    const tasks = await loadTasks();
    const task = tasks.find(candidate => candidate.label === label);

    if (!task) {
      throw new Error(`Unknown task label: ${label}`);
    }

    if (task.isBackground) {
      throw new Error(`Background task is not supported through MCP: ${label}`);
    }

    const parts = task.command.split(/\s+/).filter(Boolean);
    const [command, ...args] = parts;

    return toTextResult(await executeCommand({ command, args, timeoutSeconds }));
  }
);

server.registerTool(
  'run_repo_command',
  {
    title: 'Run Repo Command',
    description: 'Run an allowed command inside the Coffee repo. Commands are validated against .vscode/settings.json chat.tools.terminal.autoApprove and executed without a shell.',
    inputSchema: z.object({
      command: z.string().describe('Executable name, for example bin/rspec or git'),
      args: z.array(z.string()).default([]).describe('Command arguments as separate items, not a shell string.'),
      cwd: z.string().default('.').describe('Optional repo-relative working directory.'),
      timeoutSeconds: z.number().int().min(1).max(maxTimeoutSeconds).default(120)
    })
  },
  async ({ command, args, cwd, timeoutSeconds }) => {
    return toTextResult(await executeCommand({ command, args, cwd, timeoutSeconds }));
  }
);

server.registerTool(
  'inspect_routes',
  {
    title: 'Inspect Rails Routes',
    description: 'Run bin/rails routes and optionally filter the output by route name, path, verb, or controller text.',
    inputSchema: z.object({
      filter: z.string().optional().describe('Optional case-insensitive text filter for the route output.'),
      timeoutSeconds: z.number().int().min(1).max(maxTimeoutSeconds).default(120)
    })
  },
  async ({ filter, timeoutSeconds }) => {
    const result = await executeCommand({
      command: 'bin/rails',
      args: ['routes'],
      timeoutSeconds
    });

    const lines = selectRouteLines(result.stdout, filter);

    return toTextResult({
      ...result,
      filter: filter || null,
      matchingLines: lines,
      matchCount: lines.length
    });
  }
);

server.registerTool(
  'run_focused_rspec',
  {
    title: 'Run Focused RSpec',
    description: 'Run bin/rspec for a specific spec file, optionally targeting a line number or example name.',
    inputSchema: z.object({
      specPath: z.string().describe('Repo-relative path to the spec file, for example spec/models/user_spec.rb.'),
      line: z.number().int().positive().optional().describe('Optional line number to target a single example or block.'),
      example: z.string().optional().describe('Optional example name filter passed via --example.'),
      timeoutSeconds: z.number().int().min(1).max(maxTimeoutSeconds).default(900)
    })
  },
  async ({ specPath, line, example, timeoutSeconds }) => {
    return toTextResult(await runFocusedRspec({ specPath, line, example, timeoutSeconds }));
  }
);

server.registerTool(
  'run_quality_suite',
  {
    title: 'Run Quality Suite',
    description: 'Run rubocop, brakeman, and rspec in sequence and stop at the first failing step.',
    inputSchema: z.object({
      timeoutSeconds: z.number().int().min(1).max(maxTimeoutSeconds).default(900)
    })
  },
  async ({ timeoutSeconds }) => {
    return toTextResult(await runQualitySuite({ timeoutSeconds }));
  }
);

server.registerTool(
  'check_pr_checks',
  {
    title: 'Check PR Checks',
    description: 'Run gh pr checks for the current branch and return the status summary.',
    inputSchema: z.object({
      timeoutSeconds: z.number().int().min(1).max(maxTimeoutSeconds).default(120)
    })
  },
  async ({ timeoutSeconds }) => {
    return toTextResult(
      await executeCommand({
        command: 'gh',
        args: ['pr', 'checks'],
        timeoutSeconds
      })
    );
  }
);

server.registerTool(
  'read_repo_instructions',
  {
    title: 'Read Repo Instructions',
    description: 'Return the repository-specific Copilot instructions from .github/copilot-instructions.md.',
    inputSchema: z.object({})
  },
  async () => {
    const contents = await fs.readFile(instructionsPath, 'utf8');
    return toTextResult(contents);
  }
);

const transport = new StdioServerTransport();

async function main() {
  await server.connect(transport);
  console.error('coffee-tools MCP server running on stdio');
}

main().catch(error => {
  console.error('Fatal error starting coffee-tools MCP server:', error);
  process.exit(1);
});