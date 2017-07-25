# This job captures all sidekiq job exceptions, forward them to Raven and and 
# re-raise the exception to Sidekiq job runner.
#
# See https://github.com/mperham/sidekiq/wiki/Middleware#server-side-middleware
class JobRavenReporterMiddleware
  def call(_worker, _job, _queue)
    begin
      yield
    rescue => ex
      Raven.capture_exception(ex)
      raise
    end
  end
end
