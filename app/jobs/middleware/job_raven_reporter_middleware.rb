# This job captures all shoryuken job exceptions, forward them to Raven and and
# re-raise the exception to a Shoryuken job runner.
#
class JobRavenReporterMiddleware
  def call(worker_instance, queue, msg, body)
    yield
  rescue => ex
    Raven.capture_exception(ex)
    raise
  end
end
