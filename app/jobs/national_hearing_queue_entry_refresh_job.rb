# frozen_string_literal: true

class NationalHearingQueueEntryRefreshJob < CaseflowJob
  @timeout_seconds = 30

  class << self
    attr_accessor :timeout_seconds # provide class methods for reading/writing
  end

  def perform
    begin
      NationalHearingQueueEntry.refresh
    rescue ActiveRecord::StatementTimeout => error
      if self.class.timeout_seconds == 30
        self.class.timeout_seconds = 2700
        # temporarily setting timeout to allow query to run
        timeout_set(self.class.timeout_seconds)

        perform
      elsif self.class.timeout_seconds == 2700
        log_error("Timeout was set to 2700 and job timed out. Error: #{error}")
      else
        log_error(error)
      end
    rescue StandardError => error
      log_error(error)
    ensure
      # Set Timeout Back
      if self.class.timeout_seconds != 30
        self.class.timeout_seconds = 30
        timeout_set(self.class.timeout_seconds)
      end
    end
  end

  private

  def timeout_set(seconds)
    ActiveRecord::Base.connection.execute("SET statement_timeout = '#{seconds}s'")
  end
end
