class StartCertificationJob < ActiveJob::Base
  queue_as :default
  self.queue_adapter = :sidekiq


  def perform(certification, user = nil, ip_address = nil)
    RequestStore.store[:current_user] = user if user
    # Passing in ip address since it's only available when
    # the session is.
    RequestStore.store[:ip_address] = ip_address if ip_address
    # Results in calls to VBMS and VACOLS
    status = certification.start!
    certification.fetch_power_of_attorney! if status == :started
    certification.update_attributes!(
      loading_data: false,
      loading_data_failed: false
    )
  rescue => e
    Rails.logger.info "StartCertificationJob failed: #{e.message}"
    Rails.logger.info e.backtrace.join("\n")
    certification.update_attributes!(
      loading_data: false,
      loading_data_failed: true
    )
  end

  # This job will run again if the user reloads the browser.
  # We don't want to retry it otherwise.
  def max_attempts
    1
  end
end
