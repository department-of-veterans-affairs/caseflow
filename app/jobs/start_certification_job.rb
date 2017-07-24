class StartCertificationJob < ActiveJob::Base
  queue_as :default

  def perform(certification)
    # Results in calls to VBMS and VACOLS
    status = certification.start!
    certification.fetch_power_of_attorney! if status == :started
    certification.update_attributes!(
      loading: false,
      error: false
    )
  rescue
    certification.update_attributes!(
      loading: false,
      error: true
    )
  end

  # This job will restart if the user reloads the browser.
  def max_attempts
    1
  end
end
