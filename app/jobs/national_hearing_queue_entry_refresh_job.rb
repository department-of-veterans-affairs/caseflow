# frozen_string_literal: true

class NationalHearingQueueEntryRefreshJob < CaseflowJob

  @@timeout_seconds = 30

  def perform
    begin

      NationalHearingQueueEntry.refresh

    rescue ActiveRecord::StatementTimeout => error
      if @@timeout_seconds == 30
        @@timeout_seconds = 2700
        #temporarily setting timeout to allow query to run
        set_timeout(@@timeout_seconds)

        self.perform
      else
        log_error(error)
      end

    rescue StandardError => error
      log_error(error)

    ensure
      # Set Timeout Back
      if @@timeout_seconds != 30
        @@timeout_seconds = 30
        set_timeout(@@timeout_seconds)
      end
    end
  end

  private

  def set_timeout(seconds)
    ActiveRecord::Base.connection.execute("SET statement_timeout = '#{seconds}s'")
  end
end
