# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

run Rails.application

# Redirect www to apex for canonical host
use Rack::Rewrite do
	r301 %r{.*}, 'https://acercoffee.com$&', if: Proc.new { |rack_env|
		host = rack_env['HTTP_HOST'] || ''
		host.downcase.start_with?('www.acercoffee.com')
	}
end
Rails.application.load_server
