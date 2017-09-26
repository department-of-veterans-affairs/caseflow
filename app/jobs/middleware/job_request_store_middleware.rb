# This middleware makes it safe to use RequestStore inside jobs by ensuring
# that RequestStore is cleared after every job.
class JobRequestStoreMiddleware
  # :nocov:
  def call(worker_instance, queue, msg, body)
    yield
  ensure
    ::RequestStore.clear! if defined?(::RequestStore)
  end
  # :nocov:
end
