module GovDelivery::TMS #:nodoc:
  class Logger < Faraday::Response::Middleware #:nodoc:
    extend Forwardable

    def initialize(app, logger = nil)
      super(app)
      @logger = logger || begin
        require 'logger'
        ::Logger.new(STDOUT)
      end
    end

    def_delegators :@logger, :debug, :info, :warn, :error, :fatal

    def call(env)
      debug "performing #{env[:method].to_s.upcase.ljust(7)} #{env[:url]}"

      start = Time.now

      # In order to log request duration in a threadsafe way, `start` must be a local variable instead of instance variable.
      @app.call(env).on_complete do |environment|
        on_complete(environment)
        log_stuff(start, environment)
      end
    end

    private

    def log_stuff(start, environment)
      duration = Time.now - start
      info "#{environment[:method].to_s.upcase.ljust(7)}#{environment[:status].to_s.ljust(4)}#{environment[:url]} (#{duration} seconds)"
      debug('response headers') { JSON.pretty_generate environment[:response_headers] }
      debug('response body') { environment[:body] }
    end
  end
end
