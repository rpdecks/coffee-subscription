#!/usr/bin/env node

import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { parse as parseJsonc } from 'jsonc-parser';
import pdfParse from 'pdf-parse/lib/pdf-parse.js';
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

async function resolveReadablePath(filePath, { allowOutsideRepo = false } = {}) {
  if (typeof filePath !== 'string' || filePath.trim() === '') {
    throw new Error('A file path is required.');
  }

  if (filePath.includes('\n') || filePath.includes('\r')) {
    throw new Error('Newlines are not allowed in file paths.');
  }

  const resolved = path.isAbsolute(filePath)
    ? path.resolve(filePath)
    : path.resolve(repoRoot, filePath);

  if (!allowOutsideRepo) {
    if (resolved !== repoRoot && !resolved.startsWith(`${repoRoot}${path.sep}`)) {
      throw new Error('Path must stay inside the repository.');
    }
  }

  const stats = await fs.stat(resolved).catch(() => null);
  if (!stats?.isFile()) {
    throw new Error(`File not found: ${filePath}`);
  }

  return resolved;
}

async function resolveReadableDirectory(dirPath, { allowOutsideRepo = false } = {}) {
  if (typeof dirPath !== 'string' || dirPath.trim() === '') {
    throw new Error('A directory path is required.');
  }

  if (dirPath.includes('\n') || dirPath.includes('\r')) {
    throw new Error('Newlines are not allowed in directory paths.');
  }

  const resolved = path.isAbsolute(dirPath)
    ? path.resolve(dirPath)
    : path.resolve(repoRoot, dirPath);

  if (!allowOutsideRepo) {
    if (resolved !== repoRoot && !resolved.startsWith(`${repoRoot}${path.sep}`)) {
      throw new Error('Path must stay inside the repository.');
    }
  }

  const stats = await fs.stat(resolved).catch(() => null);
  if (!stats?.isDirectory()) {
    throw new Error(`Directory not found: ${dirPath}`);
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

async function executeReadOnlyBinary(command, args = []) {
  return await new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd: repoRoot,
      env: process.env,
      shell: false,
      stdio: [ 'ignore', 'pipe', 'pipe' ]
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', chunk => {
      stdout += chunk.toString('utf8');
    });

    child.stderr.on('data', chunk => {
      stderr += chunk.toString('utf8');
    });

    child.on('error', reject);
    child.on('close', code => {
      if (code === 0) {
        resolve(stdout);
        return;
      }

      reject(new Error(`${command} exited with code ${code}: ${stderr.trim() || 'unknown error'}`));
    });
  });
}

async function executeRailsMcpScript(scriptPath, payload, { timeoutSeconds = 120 } = {}) {
  const resolvedScript = await resolveReadablePath(scriptPath);
  const normalizedTimeout = Math.max(1, Math.min(timeoutSeconds, maxTimeoutSeconds));

  return await new Promise((resolve, reject) => {
    const child = spawn('bin/rails', [ 'runner', resolvedScript, JSON.stringify(payload) ], {
      cwd: repoRoot,
      env: process.env,
      shell: false,
      stdio: [ 'ignore', 'pipe', 'pipe' ]
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

      if (timedOut) {
        reject(new Error(`Rails runner timed out for ${resolvedScript}`));
        return;
      }

      if (code !== 0) {
        reject(new Error(`Rails runner failed (${code}): ${stderr.trim() || stdout.trim() || 'unknown error'}`));
        return;
      }

      const jsonText = stdout.trim().split('\n').filter(Boolean).at(-1);

      try {
        resolve(JSON.parse(jsonText));
      } catch {
        reject(new Error(`Unable to parse Rails runner output: ${stdout.trim() || '(empty output)'}`));
      }
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

function cleanPdfText(text) {
  return text
    .replace(/\u0000/g, ' ')
    .replace(/\r/g, '\n')
    .replace(/[\t\f\v]+/g, ' ')
    .replace(/[ ]{2,}/g, ' ')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

function toNonEmptyLines(text) {
  return text
    .split('\n')
    .map(line => line.trim())
    .filter(Boolean);
}

function normalizeLabel(text) {
  return text.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
}

function isLikelySectionHeading(line) {
  const cleaned = line.replace(/[^A-Za-z ]/g, '').trim();

  if (cleaned.length < 3 || cleaned.length > 40) {
    return false;
  }

  return cleaned === cleaned.toUpperCase() && /[A-Z]/.test(cleaned);
}

function titleizeFilename(filename) {
  return path.basename(filename, path.extname(filename))
    .replace(/[_-]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .replace(/\b\w/g, char => char.toUpperCase());
}

function parseLabelValue(text, labels) {
  for (const label of labels) {
    const pattern = new RegExp(`${label}\\s*[:\\-]\\s*([^\\n]+)`, 'i');
    const match = text.match(pattern);

    if (match?.[1]) {
      return match[1].trim();
    }
  }

  const lines = toNonEmptyLines(text);
  const normalizedLabels = labels.map(normalizeLabel);

  for (let index = 0; index < lines.length; index += 1) {
    const normalizedLine = normalizeLabel(lines[index]);
    const matchesLabel = normalizedLabels.some(label => normalizedLine === label || normalizedLine.startsWith(label));

    if (!matchesLabel) {
      continue;
    }

    const collected = [];

    for (let nextIndex = index + 1; nextIndex < lines.length && collected.length < 5; nextIndex += 1) {
      const nextLine = lines[nextIndex];
      const normalizedNextLine = normalizeLabel(nextLine);

      if (normalizedLabels.includes(normalizedNextLine) || isLikelySectionHeading(nextLine)) {
        break;
      }

      if (/^coffee details$/i.test(nextLine) || /^coffee background$/i.test(nextLine)) {
        break;
      }

      collected.push(nextLine);
    }

    if (collected.length > 0) {
      return collected.join(' ');
    }
  }

  return null;
}

async function renderPdfPreviewImage(pdfPath) {
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'coffee-mcp-preview-'));

  try {
    await executeReadOnlyBinary('qlmanage', [ '-t', '-s', '2000', '-o', tempDir, pdfPath ]);

    const previewPath = path.join(tempDir, `${path.basename(pdfPath)}.png`);
    const stats = await fs.stat(previewPath).catch(() => null);

    if (!stats?.isFile()) {
      throw new Error(`Quick Look preview not generated for ${pdfPath}`);
    }

    return { tempDir, previewPath };
  } catch (error) {
    await fs.rm(tempDir, { recursive: true, force: true });
    throw error;
  }
}

async function runVisionOcr(imagePath) {
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'coffee-mcp-ocr-'));
  const scriptPath = path.join(tempDir, 'vision_ocr.swift');
  const script = [
    'import Foundation',
    'import Vision',
    'import AppKit',
    '',
    'let imagePath = CommandLine.arguments[1]',
    'let imageURL = URL(fileURLWithPath: imagePath)',
    'guard let image = NSImage(contentsOf: imageURL) else {',
    '  fputs("Failed to load image\\n", stderr)',
    '  exit(1)',
    '}',
    'var rect = CGRect(origin: .zero, size: image.size)',
    'guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {',
    '  fputs("Failed to create CGImage\\n", stderr)',
    '  exit(1)',
    '}',
    'let request = VNRecognizeTextRequest() ',
    'request.recognitionLevel = .accurate',
    'request.usesLanguageCorrection = true',
    'let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])',
    'try handler.perform([request])',
    'let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\\n")',
    'print(text)'
  ].join('\n');

  await fs.writeFile(scriptPath, script, 'utf8');

  try {
    return await executeReadOnlyBinary('swift', [ scriptPath, imagePath ]);
  } finally {
    await fs.rm(tempDir, { recursive: true, force: true });
  }
}

async function extractPdfTextViaOcr(pdfPath) {
  const { tempDir, previewPath } = await renderPdfPreviewImage(pdfPath);

  try {
    const text = await runVisionOcr(previewPath);
    return cleanPdfText(text);
  } finally {
    await fs.rm(tempDir, { recursive: true, force: true });
  }
}

function pickProductName(lines, fallbackName) {
  const banned = [
    /fact\s*sheet/i,
    /coffee\s*profile/i,
    /cupping/i,
    /^page\s+\d+/i,
    /^lot\b/i,
    /^crop\b/i,
    /^origin\b/i,
    /^region\b/i,
    /^producer\b/i,
    /^variety\b/i,
    /^process\b/i
  ];

  const candidate = lines.slice(0, 12).find(line => {
    if (line.length < 4 || line.length > 80) {
      return false;
    }

    if (banned.some(pattern => pattern.test(line))) {
      return false;
    }

    const words = line.split(/\s+/).length;
    return words >= 1 && words <= 8;
  });

  return candidate || fallbackName;
}

function buildProductDescription(extracted, cleanedText) {
  const parts = [];

  if (extracted.origin || extracted.region) {
    parts.push(`Origin: ${[extracted.origin, extracted.region].filter(Boolean).join(', ')}`);
  }

  if (extracted.producer) {
    parts.push(`Producer: ${extracted.producer}`);
  }

  if (extracted.variety) {
    parts.push(`Variety: ${extracted.variety}`);
  }

  if (extracted.process) {
    parts.push(`Process: ${extracted.process}`);
  }

  if (extracted.altitude) {
    parts.push(`Altitude: ${extracted.altitude}`);
  }

  if (extracted.harvest) {
    parts.push(`Harvest: ${extracted.harvest}`);
  }

  if (extracted.tastingNotes) {
    parts.push(`Tasting notes: ${extracted.tastingNotes}`);
  }

  if (parts.length > 0) {
    return parts.join('\n');
  }

  const paragraph = cleanedText
    .split(/\n\n+/)
    .map(block => block.trim())
    .find(block => block.length >= 40);

  if (!paragraph) {
    return null;
  }

  return paragraph.slice(0, 600);
}

async function extractPdfText(pdfPath) {
  const resolvedPath = await resolveReadablePath(pdfPath, { allowOutsideRepo: true });
  const buffer = await fs.readFile(resolvedPath);

  let parsedText = '';
  let pageCount = null;
  let parseError = null;

  try {
    const parsed = await pdfParse(buffer);
    parsedText = parsed.text || '';
    pageCount = parsed.numpages || null;
  } catch (error) {
    parseError = error;
  }

  if (!parsedText && process.platform === 'darwin') {
    try {
      const spotlightText = await executeReadOnlyBinary('mdls', [ '-raw', '-name', 'kMDItemTextContent', resolvedPath ]);

      if (!/^\(null\)\s*$/i.test(spotlightText.trim())) {
        parsedText = spotlightText;
      }
    } catch {
      // Ignore fallback failure and surface the original parse error below if needed.
    }
  }

  if (!parsedText && process.platform === 'darwin') {
    try {
      parsedText = await extractPdfTextViaOcr(resolvedPath);
    } catch {
      // Ignore OCR fallback failure and surface the original parse error below if needed.
    }
  }

  const cleanedText = cleanPdfText(parsedText);

  if (!cleanedText) {
    if (parseError) {
      throw new Error(`Unable to extract text from PDF: ${pdfPath}. ${parseError.message}`);
    }

    throw new Error(`No text could be extracted from PDF: ${pdfPath}`);
  }

  return {
    resolvedPath,
    cleanedText,
    lineCount: toNonEmptyLines(cleanedText).length,
    pageCount
  };
}

async function draftProductFromPdf({
  pdfPath,
  productType,
  roastType,
  price,
  weightOz,
  inventoryCount,
  active,
  visibleInShop,
  stripeProductId,
  stripePriceId
}) {
  const { resolvedPath, cleanedText, lineCount, pageCount } = await extractPdfText(pdfPath);
  const lines = toNonEmptyLines(cleanedText);
  const fallbackName = titleizeFilename(resolvedPath);

  const extracted = {
    origin: parseLabelValue(cleanedText, [ 'origin', 'country of origin', 'country' ]),
    region: parseLabelValue(cleanedText, [ 'region', 'growing region' ]),
    producer: parseLabelValue(cleanedText, [ 'producer', 'farm', 'producer name' ]),
    variety: parseLabelValue(cleanedText, [ 'variety', 'cultivar' ]),
    process: parseLabelValue(cleanedText, [ 'process', 'processing' ]),
    altitude: parseLabelValue(cleanedText, [ 'altitude', 'elevation' ]),
    harvest: parseLabelValue(cleanedText, [ 'harvest', 'harvest schedule', 'crop year' ]),
    tastingNotes: parseLabelValue(cleanedText, [ 'tasting notes', 'cup profile', 'flavor notes' ])
  };

  const product = {
    name: pickProductName(lines, fallbackName),
    description: buildProductDescription(extracted, cleanedText),
    productType,
    roastType: roastType || null,
    price: price ?? null,
    weightOz: weightOz ?? null,
    inventoryCount: inventoryCount ?? null,
    active,
    visibleInShop,
    stripeProductId: stripeProductId || null,
    stripePriceId: stripePriceId || null
  };

  const inferredFields = Object.entries({
    name: product.name,
    description: product.description,
    productType: product.productType,
    active: product.active,
    visibleInShop: product.visibleInShop,
    origin: extracted.origin,
    region: extracted.region,
    variety: extracted.variety,
    process: extracted.process,
    tastingNotes: extracted.tastingNotes
  })
    .filter(([, value]) => value !== null && value !== undefined && value !== '')
    .map(([key]) => key);

  const missingRequired = [];

  if (!product.name) {
    missingRequired.push('name');
  }

  if (product.price === null) {
    missingRequired.push('price');
  }

  return {
    sourcePdf: resolvedPath,
    pageCount,
    lineCount,
    readyToCreate: missingRequired.length === 0,
    missingRequired,
    inferredFields,
    extracted,
    product,
    textPreview: cleanedText.slice(0, 1200)
  };
}

async function collectPdfFiles(rootDir, { recurse, maxFiles }) {
  const queue = [rootDir];
  const results = [];

  while (queue.length > 0 && results.length < maxFiles) {
    const currentDir = queue.shift();
    const entries = await fs.readdir(currentDir, { withFileTypes: true });
    entries.sort((left, right) => left.name.localeCompare(right.name));

    for (const entry of entries) {
      const entryPath = path.join(currentDir, entry.name);

      if (entry.isDirectory()) {
        if (recurse) {
          queue.push(entryPath);
        }

        continue;
      }

      if (!entry.isFile() || !entry.name.toLowerCase().endsWith('.pdf')) {
        continue;
      }

      results.push(entryPath);
      if (results.length >= maxFiles) {
        break;
      }
    }
  }

  return results;
}

async function draftProductsFromFolder({
  folderPath,
  recurse,
  maxFiles,
  productType,
  roastType,
  price,
  weightOz,
  inventoryCount,
  active,
  visibleInShop,
  stripeProductId,
  stripePriceId
}) {
  const resolvedFolder = await resolveReadableDirectory(folderPath, { allowOutsideRepo: true });
  const pdfFiles = await collectPdfFiles(resolvedFolder, { recurse, maxFiles });

  const drafts = [];
  const errors = [];

  for (const pdfPath of pdfFiles) {
    try {
      const draft = await draftProductFromPdf({
        pdfPath,
        productType,
        roastType,
        price,
        weightOz,
        inventoryCount,
        active,
        visibleInShop,
        stripeProductId,
        stripePriceId
      });

      drafts.push({
        sourcePdf: draft.sourcePdf,
        readyToCreate: draft.readyToCreate,
        missingRequired: draft.missingRequired,
        inferredFields: draft.inferredFields,
        product: draft.product,
        extracted: draft.extracted
      });
    } catch (error) {
      errors.push({
        sourcePdf: pdfPath,
        error: error.message
      });
    }
  }

  return {
    folderPath: resolvedFolder,
    recurse,
    maxFiles,
    pdfCount: pdfFiles.length,
    draftCount: drafts.length,
    errorCount: errors.length,
    drafts,
    errors
  };
}

async function createProductFromDraft({ timeoutSeconds = 120, ...productDraft }) {
  return await executeRailsMcpScript('scripts/mcp/create_product_from_draft.rb', productDraft, { timeoutSeconds });
}

async function createProductFromPdf({ timeoutSeconds = 120, ...input }) {
  const draft = await draftProductFromPdf(input);

  if (!draft.readyToCreate) {
    return {
      success: false,
      errors: [ `Draft is missing required fields: ${draft.missingRequired.join(', ')}` ],
      draft
    };
  }

  const creation = await createProductFromDraft({ ...draft.product, timeoutSeconds });

  return {
    ...creation,
    draft
  };
}

async function recordRoastAndPackageInventory({ timeoutSeconds = 120, ...input }) {
  return await executeRailsMcpScript('scripts/mcp/record_roast_and_package_inventory.rb', input, { timeoutSeconds });
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

server.registerTool(
  'draft_product_from_pdf',
  {
    title: 'Draft Product From PDF',
    description: 'Read a local PDF fact sheet and build a conservative product draft for the admin product form. Intended for filesystem paths, not chat attachment blobs.',
    inputSchema: z.object({
      pdfPath: z.string().describe('Absolute path to a PDF file, or a repo-relative path inside this workspace.'),
      productType: z.enum([ 'coffee', 'merch' ]).default('coffee').describe('Product type to assign to the draft.'),
      roastType: z.enum([ 'signature', 'light', 'medium', 'dark' ]).optional().describe('Optional roast type override for coffee products.'),
      price: z.number().positive().optional().describe('Optional price in dollars. Provide this when you want a create-ready draft.'),
      weightOz: z.number().positive().optional().describe('Optional bag weight in ounces.'),
      inventoryCount: z.number().int().min(0).optional().describe('Optional inventory count.'),
      active: z.boolean().default(false).describe('Whether the new product should be active. Defaults to false for safety.'),
      visibleInShop: z.boolean().default(false).describe('Whether the new product should be visible in the shop. Defaults to false for safety.'),
      stripeProductId: z.string().optional().describe('Optional Stripe product ID override.'),
      stripePriceId: z.string().optional().describe('Optional Stripe price ID override.')
    })
  },
  async input => {
    return toTextResult(await draftProductFromPdf(input));
  }
);

server.registerTool(
  'draft_products_from_folder',
  {
    title: 'Draft Products From Folder',
    description: 'Read all PDF files from a local folder or synced cloud folder and build conservative product drafts for each file.',
    inputSchema: z.object({
      folderPath: z.string().default('tmp/agent-inputs').describe('Absolute path to a PDF folder, or a repo-relative folder inside this workspace.'),
      recurse: z.boolean().default(false).describe('Whether to scan nested subdirectories.'),
      maxFiles: z.number().int().min(1).max(100).default(25).describe('Maximum number of PDFs to process in one invocation.'),
      productType: z.enum([ 'coffee', 'merch' ]).default('coffee').describe('Product type to assign to each draft.'),
      roastType: z.enum([ 'signature', 'light', 'medium', 'dark' ]).optional().describe('Optional roast type override for coffee products.'),
      price: z.number().positive().optional().describe('Optional shared price in dollars for all drafts.'),
      weightOz: z.number().positive().optional().describe('Optional shared bag weight in ounces.'),
      inventoryCount: z.number().int().min(0).optional().describe('Optional shared inventory count.'),
      active: z.boolean().default(false).describe('Whether drafted products should default to active. Defaults to false for safety.'),
      visibleInShop: z.boolean().default(false).describe('Whether drafted products should default to visible in shop. Defaults to false for safety.'),
      stripeProductId: z.string().optional().describe('Optional shared Stripe product ID override.'),
      stripePriceId: z.string().optional().describe('Optional shared Stripe price ID override.')
    })
  },
  async input => {
    return toTextResult(await draftProductsFromFolder(input));
  }
);

server.registerTool(
  'create_product_from_draft',
  {
    title: 'Create Product From Draft',
    description: 'Create a Product record programmatically from explicit draft fields using the Rails app, bypassing manual admin form entry.',
    inputSchema: z.object({
      name: z.string().describe('Product name.'),
      description: z.string().optional().describe('Optional storefront description.'),
      productType: z.enum([ 'coffee', 'merch' ]).default('coffee').describe('Product type to create.'),
      roastType: z.enum([ 'signature', 'light', 'medium', 'dark' ]).optional().describe('Optional roast type for coffee products.'),
      price: z.number().positive().describe('Retail price in dollars.'),
      weightOz: z.number().positive().optional().describe('Optional bag weight in ounces.'),
      inventoryCount: z.number().int().min(0).optional().describe('Optional inventory count.'),
      active: z.boolean().default(false).describe('Whether the created product should be active.'),
      visibleInShop: z.boolean().default(false).describe('Whether the created product should be visible in the shop.'),
      stripeProductId: z.string().optional().describe('Optional Stripe product ID.'),
      stripePriceId: z.string().optional().describe('Optional Stripe price ID.'),
      timeoutSeconds: z.number().int().min(1).max(maxTimeoutSeconds).default(120)
    })
  },
  async ({
    name,
    description,
    productType,
    roastType,
    price,
    weightOz,
    inventoryCount,
    active,
    visibleInShop,
    stripeProductId,
    stripePriceId,
    timeoutSeconds
  }) => {
    return toTextResult(await createProductFromDraft({
      name,
      description,
      product_type: productType,
      roast_type: roastType,
      price,
      weight_oz: weightOz,
      inventory_count: inventoryCount,
      active,
      visible_in_shop: visibleInShop,
      stripe_product_id: stripeProductId,
      stripe_price_id: stripePriceId,
      timeoutSeconds
    }));
  }
);

server.registerTool(
  'create_product_from_pdf',
  {
    title: 'Create Product From PDF',
    description: 'Build a product draft from a local PDF fact sheet and create the Product record programmatically when required fields are present.',
    inputSchema: z.object({
      pdfPath: z.string().describe('Absolute path to a PDF file, or a repo-relative path inside this workspace.'),
      productType: z.enum([ 'coffee', 'merch' ]).default('coffee').describe('Product type to assign to the new product.'),
      roastType: z.enum([ 'signature', 'light', 'medium', 'dark' ]).optional().describe('Optional roast type override for coffee products.'),
      price: z.number().positive().describe('Retail price in dollars.'),
      weightOz: z.number().positive().optional().describe('Optional bag weight in ounces.'),
      inventoryCount: z.number().int().min(0).optional().describe('Optional inventory count.'),
      active: z.boolean().default(false).describe('Whether the created product should be active.'),
      visibleInShop: z.boolean().default(false).describe('Whether the created product should be visible in the shop.'),
      stripeProductId: z.string().optional().describe('Optional Stripe product ID override.'),
      stripePriceId: z.string().optional().describe('Optional Stripe price ID override.'),
      timeoutSeconds: z.number().int().min(1).max(maxTimeoutSeconds).default(120)
    })
  },
  async input => {
    return toTextResult(await createProductFromPdf(input));
  }
);

server.registerTool(
  'record_roast_and_package_inventory',
  {
    title: 'Record Roast And Package Inventory',
    description: 'Record roasted output, create packaged inventory, and optionally debit a GreenCoffee lot in one operation so a coffee product becomes sellable without manual admin entry.',
    inputSchema: z.object({
      productId: z.number().int().positive().describe('Product ID for the sellable coffee SKU.'),
      greenCoffeeId: z.number().int().positive().optional().describe('Optional GreenCoffee ID to debit from source inventory.'),
      greenWeightUsed: z.number().positive().optional().describe('Green coffee pounds consumed in the roast. Required when recording a new roast.'),
      roastedWeight: z.number().positive().optional().describe('Roasted coffee pounds produced. Optional when only packaging existing roasted inventory.'),
      packagedWeight: z.number().positive().optional().describe('Packaged coffee pounds added to sellable stock.'),
      roastedOn: z.string().optional().describe('Roast date in YYYY-MM-DD format. Required for new roast and packaged entries.'),
      lotNumber: z.string().optional().describe('Optional lot number for roast/package traceability.'),
      batchId: z.string().optional().describe('Optional roast batch identifier.'),
      expiresOn: z.string().optional().describe('Optional expiration date in YYYY-MM-DD format.'),
      notes: z.string().optional().describe('Optional notes stored on created inventory entries.'),
      timeoutSeconds: z.number().int().min(1).max(maxTimeoutSeconds).default(120)
    })
  },
  async ({
    productId,
    greenCoffeeId,
    greenWeightUsed,
    roastedWeight,
    packagedWeight,
    roastedOn,
    lotNumber,
    batchId,
    expiresOn,
    notes,
    timeoutSeconds
  }) => {
    return toTextResult(await recordRoastAndPackageInventory({
      product_id: productId,
      green_coffee_id: greenCoffeeId,
      green_weight_used: greenWeightUsed,
      roasted_weight: roastedWeight,
      packaged_weight: packagedWeight,
      roasted_on: roastedOn,
      lot_number: lotNumber,
      batch_id: batchId,
      expires_on: expiresOn,
      notes,
      timeoutSeconds
    }));
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