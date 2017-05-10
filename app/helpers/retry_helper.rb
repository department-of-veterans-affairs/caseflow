module RetryHelper
  def retry_when(error_klass, limit: 3, &_block)
    retry_count ||= 0
    yield
  rescue error_klass => e
    Rails.logger.warn "RetryHelper rescuing from #{error_klass}. #{e.backtrace.join("\n")}"
    retry if (retry_count += 1) <= limit

    # If we're past the retry limit, re-raise the original error
    raise
  end

  # Include the instance methods on the class level too
  def self.included(receiver)
    receiver.extend self
  end
end
