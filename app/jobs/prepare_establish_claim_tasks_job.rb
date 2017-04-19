class PrepareEstablishClaimTasksJob < ActiveJob::Base
  queue_as :default

  def perform
    @prepared_count = EstablishClaim.unprepared.inject(0) do |count, task|
      count + (task.prepare_with_decision! == :success ? 1 : 0)
    end

    log_result
  end

  private

  def log_result
    Rails.logger.info "Successfully prepared #{@prepared_count} tasks"

    not_enough_prepared_check!
  end

  def not_enough_prepared_check!
    if workday? && (@prepared_count < expected_minimum)
      fail Caseflow::Error::NotEnoughTasksPrepared
    end
  end

  # TODO: This should include holidays, but don't have a great way to do that.
  # So we're okay with an error firing on holidays
  def workday?
    !(next_workday.saturday? || next_workday.sunday?)
  end

  def next_workday
    (Time.zone.now + 12.hours).to_date
  end

  def expected_minimum
    10
  end
end
