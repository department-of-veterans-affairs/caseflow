# frozen_string_literal: true

class NationalHearingQueueEntryRefreshJob < CaseflowJob
  def initialize
    @timeout_seconds = 30

    super
  end

  def perform
    begin
      # NationalHearingQueueEntry.refresh

      # For testing the timeout logic
      ActiveRecord::Base.connection.execute("SELECT pg_sleep(45)")
    rescue ActiveRecord::QueryCanceled => error
      handle_timeout(error)
    rescue StandardError => error
      log_error(error)
    ensure
      # Set Timeout Back
      if @timeout_seconds != 30
        timeout_set(30)
      end
    end
  end

  private

  def handle_timeout(error)
    if @timeout_seconds == 30
      # temporarily setting timeout to allow query to run
      timeout_set(2700)
      perform
    else
      Rails.logger.error("Timeout was set to #{@timeout_seconds} seconds and job timed out.")
      log_error(error)
    end
  end

  def timeout_set(seconds)
    @timeout_seconds = 2700

    ActiveRecord::Base.connection.execute("SET statement_timeout = '#{seconds}s'")
  end
end
