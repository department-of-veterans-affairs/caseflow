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