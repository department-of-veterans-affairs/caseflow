# This middleware makes it safe to use RequestStore inside jobs by ensuring
# that RequestStore is cleared after every job.
class JobRequestStoreMiddleware
  def call(worker, msg, queue)
    yield
  ensure
    ::RequestStore.clear! if defined?(::RequestStore)
  end
end
