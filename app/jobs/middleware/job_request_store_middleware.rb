# This middleware makes it safe to use RequestStore inside jobs by ensuring
# that RequestStore is cleared after every job.
class JobRequestStoreMiddleware
  # :nocov:
  def call(_worker, _msg, _queue)
    yield
  ensure
    ::RequestStore.clear! if defined?(::RequestStore)
  end
  # :nocov:
end
