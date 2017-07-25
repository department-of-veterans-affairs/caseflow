class JobRavenReporterMiddleware
  def call(worker, job, queue)
    begin
      yield
    rescue => ex
      Raven.capture_exception(ex)
    end
  end
end