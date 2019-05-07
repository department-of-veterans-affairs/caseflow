# frozen_string_literal: true

module RetryHelper
  def retry_when(error_klass, limit: 3, &_block)
    retry_count ||= 0
    yield
  rescue error_klass => error
    Rails.logger.warn "RetryHelper rescuing from #{error_klass}. #{error.backtrace.join("\n")}"
    retry if (retry_count += 1) <= limit

    # If we're past the retry limit, re-raise the original error
    raise
  end

  # Include the instance methods on the class level too
  def self.included(receiver)
    receiver.extend self
  end
end
