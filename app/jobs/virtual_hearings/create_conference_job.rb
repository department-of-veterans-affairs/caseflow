# frozen_string_literal: true

# This job will create a conference for a hearing
# that is switched to virtual hearing.
class VirtualHearings::CreateConferenceJob < VirtualHearings::ConferenceJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :high_priority
  application_attr :hearing_schedule

  class IncompleteError < StandardError; end

  class VirtualHearingRequestCancelled < StandardError; end

  # We are observing some lag (replication?) when creating the virtual hearing for the first time
  # in the database. This error is thrown if the virtual hearing is not visible in the database
  # at the time this job is started.
  class VirtualHearingNotCreatedError < StandardError; end

  class VirtualHearingLinkGenerationFailed < StandardError; end

  discard_on(VirtualHearingLinkGenerationFailed) do |job, _exception|
    Rails.logger.warn(
      "Discarding #{job.class.name} (#{job.job_id}) because links could not be generated"
    )
  end

  discard_on(VirtualHearingRequestCancelled) do |job, _exception|
    Rails.logger.warn(
      "Discarding #{job.class.name} (#{job.job_id}) because virtual hearing request was cancelled"
    )
  end

  retry_on(IncompleteError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")
  end

  retry_on(VirtualHearingNotCreatedError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")
  end

  # Retry if Pexip returns an invalid response.
  retry_on(Caseflow::Error::PexipApiError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")

    kwargs = job.arguments.first
    extra = {
      application: job.class.app_name.to_s,
      hearing_id: kwargs[:hearing_id],
      hearing_type: kwargs[:hearing_type]
    }

    Raven.capture_exception(exception, extra: extra)
  end

  # Log the timezone of the job. This is primarily used for debugging context around times
  # that appear in the hearings notification emails.
  before_perform do |job|
    kwargs = job.arguments.first
    hearing_id = kwargs[:hearing_id]
    email_type = kwargs[:email_type] || :confirmation

    Rails.logger.info(
      "#{self.class.name} for hearing (#{hearing_id}) and sending #{email_type} email"
    )
    Rails.logger.info(
      "Timezones for #{self.class.name} are (zone: #{Time.zone.name}) (getlocal: #{Time.now.getlocal.zone})"
    )
  end

  def perform(hearing_id:, hearing_type:, email_type: :confirmation)
    ensure_current_user_is_set

    set_virtual_hearing(hearing_id, hearing_type)

    log_virtual_hearing_state(virtual_hearing)

    virtual_hearing.establishment.attempted!

    # successfully creating a conference will make the virtual hearing active
    create_conference unless virtual_hearing.active?

    # when a conference has been created and emails sent, the virtual hearing can be established
    begin
      send_emails(email_type) if virtual_hearing.active?
    rescue StandardError => error
      Raven.capture_exception(error, extra: { virtual_hearing_id: virtual_hearing.id, email_type: email_type })
    end

    if virtual_hearing.can_be_established?
      Rails.logger.info("Attempting to flag virtual hearing establishment as processed...")

      virtual_hearing.established!
    else
      Rails.logger.error(
        "Virtual Hearing can't be established with state: " \
        "(email sent?: #{virtual_hearing.all_emails_sent?}, active?: #{virtual_hearing.active?})"
      )

      fail IncompleteError
    end
  end

  private

  attr_reader :virtual_hearing

  def set_virtual_hearing(hearing_id, hearing_type)
    case hearing_type
    when Hearing.name
      @virtual_hearing = Hearing.find(hearing_id).virtual_hearing
    when LegacyHearing.name
      @virtual_hearing = LegacyHearing.find(hearing_id).virtual_hearing
    else
      fail ArgumentError, "Invalid hearing type supplied to job: `#{hearing_type}`"
    end

    fail VirtualHearingNotCreatedError if virtual_hearing.nil?
    fail VirtualHearingRequestCancelled if virtual_hearing.cancelled?
  end

  def log_virtual_hearing_state(virtual_hearing)
    super

    Rails.logger.info("Active?: (#{virtual_hearing.active?})")
    Rails.logger.info("Virtual Hearing Updated At: (#{virtual_hearing.updated_at})")
    Rails.logger.info("Establishment Updated At: (#{virtual_hearing.establishment.updated_at})")
  end

  def create_conference_datadog_tags
    datadog_metric_info.merge(attrs: { hearing_id: virtual_hearing.hearing_id })
  end

  def create_conference
    if FeatureToggle.enabled?(:virtual_hearings_use_new_links, user: virtual_hearing.updated_by)
      generate_links_and_pins
    else
      assign_virtual_hearing_alias_and_pins if should_initialize_alias_and_pins?

      Rails.logger.info(
        "Trying to create conference for hearing (#{virtual_hearing.hearing_type} " \
        "[#{virtual_hearing.hearing_id}])..."
      )

      pexip_response = create_pexip_conference

      Rails.logger.info("Pexip response: #{pexip_response.inspect}")

      if pexip_response.error
        error_display = pexip_error_display(pexip_response)

        Rails.logger.error("CreateConferenceJob failed: #{error_display}")

        virtual_hearing.establishment.update_error!(error_display)

        DataDogService.increment_counter(metric_name: "created_conference.failed", **create_conference_datadog_tags)

        fail pexip_response.error
      end

      DataDogService.increment_counter(metric_name: "created_conference.successful", **create_conference_datadog_tags)

      virtual_hearing.update(conference_id: pexip_response.data[:conference_id])
    end
  end

  def send_emails(email_type)
    VirtualHearings::SendEmail.new(
      virtual_hearing: virtual_hearing,
      type: email_type
    ).call
  end

  def pexip_error_display(response)
    "(#{response.error.code}) #{response.error.message}"
  end

  def create_pexip_conference
    client.create_conference(
      host_pin: virtual_hearing.host_pin,
      guest_pin: virtual_hearing.guest_pin,
      name: virtual_hearing.alias
    )
  end

  def should_initialize_alias_and_pins?
    virtual_hearing.alias.nil? || virtual_hearing.host_pin.nil? || virtual_hearing.guest_pin.nil?
  end

  def assign_virtual_hearing_alias_and_pins
    # Using pessimistic locking here because no other processes should be reading
    # the record while maximum is being calculated.
    virtual_hearing.with_lock do
      max_alias = VirtualHearing.maximum(:alias)
      conference_alias = max_alias ? (max_alias.to_i + 1).to_s.rjust(7, "0") : "0000001"
      virtual_hearing.alias = conference_alias
      virtual_hearing.alias_with_host = VirtualHearing.formatted_alias(conference_alias)
      virtual_hearing.generate_conference_pins
      virtual_hearing.save!
    end
  end

  def generate_links_and_pins
    Rails.logger.info(
      "Trying to create virtual hearings links (#{virtual_hearing.hearing_type} " \
      "[#{virtual_hearing.hearing_id}])..."
    )
    begin
      link_service = VirtualHearings::LinkService.new
      virtual_hearing.update!(
        host_hearing_link: link_service.host_link,
        guest_hearing_link: link_service.guest_link,
        host_pin_long: link_service.host_pin,
        guest_pin_long: link_service.guest_pin,
        alias_with_host: link_service.alias_with_host
      )
    rescue StandardError => error
      Raven.capture_exception(error: error)
      raise VirtualHearingLinkGenerationFailed
    end
  end
end
