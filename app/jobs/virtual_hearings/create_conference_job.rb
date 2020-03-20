# frozen_string_literal: true

# This job will create a conference for a hearing
# that is switched to virtual hearing.
class VirtualHearings::CreateConferenceJob < ApplicationJob
  include VirtualHearings::PexipClient

  queue_with_priority :high_priority

  retry_on Caseflow::Error::PexipApiError, attempts: 5 do |_job, exception|
    extra = {
      hearing_id: virtual_hearing.hearing_id,
      hearing_type: virtual_hearing.hearing_type
    }

    capture_exception(exception, extra: extra)
  end

  before_perform do |job|
    kwargs = job.arguments.first
    hearing_id = kwargs[:hearing_id]
    email_type = kwargs[:email_type] || :confirmation

    Rails.logger.info(
      "Creating Pexip conference for hearing (#{hearing_id}) and sending #{email_type} email"
    )
    Rails.logger.info(
      "Timezones for #{self.class.name} are (zone: #{Time.zone.name}) (getlocal: #{Time.now.getlocal.zone})"
    )
  end

  def perform(hearing_id:, hearing_type:, email_type: :confirmation)
    set_virtual_hearing(hearing_id, hearing_type)

    virtual_hearing.establishment.attempted!

    create_conference if !virtual_hearing.conference_id || !virtual_hearing.alias

    VirtualHearings::SendEmail.new(
      virtual_hearing: virtual_hearing,
      type: email_type
    ).call if virtual_hearing.conference_id

    if virtual_hearing.active? && virtual_hearing.all_emails_sent?
      virtual_hearing.establishment.clear_error!
      virtual_hearing.establishment.processed!
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
  end

  def create_conference
    assign_virtual_hearing_alias_and_pins if should_initialize_alias_and_pins?

    resp = client.create_conference(
      host_pin: virtual_hearing.host_pin,
      guest_pin: virtual_hearing.guest_pin,
      name: virtual_hearing.alias
    )

    if resp.error
      Rails.logger.info("Pexip response: #{resp}")
      Rails.logger.error "CreateConferenceJob failed: (#{resp.error.code}) #{resp.error.message}"

      virtual_hearing.establishment.update_error!("(#{resp.error.code}) #{resp.error.message}")

      fail resp.error
    end

    virtual_hearing.update(conference_id: resp.data[:conference_id], status: :active)
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
      virtual_hearing.host_pin = rand(1000..9999)
      virtual_hearing.guest_pin = rand(1000..9999)
      virtual_hearing.save!
    end
  end
end
