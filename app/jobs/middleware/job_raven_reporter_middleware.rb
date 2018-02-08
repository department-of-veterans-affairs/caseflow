# This job captures all Shoryuken job exceptions and forwards them to Raven.
#
class JobRavenReporterMiddleware
  def call(_worker, _queue, _msg, _body)
    yield
  rescue StandardError => ex
    tags = {job: _body['job_class'], queue: _queue}
    context = {message: _body}
    Raven.capture_exception(ex, tags: tags, extra: context)
    raise
  end
end
