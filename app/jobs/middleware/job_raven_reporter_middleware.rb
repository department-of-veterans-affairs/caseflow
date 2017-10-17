# This job captures all shoryuken job exceptions, forward them to Raven and and
# re-raise the exception to a Shoryuken job runner.
#
class JobRavenReporterMiddleware
  def call(_worker, _queue, _msg, _body)
    yield
  rescue => ex
    Raven.capture_exception(ex)
    raise
  end
end
