# Perform basic auth on the Prometheus /metrics endpoint so that we do not
# expose sensitive data in the open.
class MetricsAuth < Rack::Auth::Basic
  def call(env)
    request = Rack::Request.new(env)
    case request.path

    when "/metrics" # perform auth for /metrics
      super
    else # skip auth otherwise
      @app.call(env)
    end
  end
end
