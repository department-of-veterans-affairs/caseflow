# This job captures all Shoryuken job exceptions and forwards them to Raven.
#
class JobRavenReporterMiddleware
  def call(_worker, queue, _msg, body)
    yield
  rescue StandardError => ex
    tags = { job: body["job_class"], queue: queue }
    context = { message: body }
    Raven.capture_exception(ex, tags: tags, extra: context)
    raise
  end
end
