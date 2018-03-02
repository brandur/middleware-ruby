require 'logger'
require 'rack'
require 'rack/server'
require 'securerandom'

#
# Composition
#

class LogInitializerMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    logger = Logger.new(STDOUT)

    original_formatter = Logger::Formatter.new
    logger.formatter = ->(severity, datetime, progname, msg) {
      msg = "Request #{env['app.request_id']}: #{msg}"
      original_formatter.call(severity, datetime, progname, msg)
    }

    env['app.logger'] = logger
    @app.call(env)
  end
end

class RequestIDMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request_id = SecureRandom.uuid
    env['app.request_id'] = request_id
    env['app.logger'].debug "Generated request ID: #{request_id}"
    @app.call(env)
  end
end

#
# App
#

class HelloWorldApp
  def self.call(env)
    [200, {}, ['Hello World']]
  end
end

#
# Composition
#

app = Rack::Builder.new do
  use LogInitializerMiddleware
  use RequestIDMiddleware
  run HelloWorldApp
end

Rack::Server.start app: app
