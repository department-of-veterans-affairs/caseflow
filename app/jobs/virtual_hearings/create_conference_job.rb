# frozen_string_literal: true

# This job will create a conference for a hearing
# that is switched to virtual hearing.
class VirtualHearings::CreateConferenceJob < ApplicationJob
  include VirtualHearings::PexipClient

  queue_with_priority :high_priority

  attr_reader :virtual_hearing

  retry_on Caseflow::Error::PexipApiError, attempts: 5 do |_job, exception|
    capture_exception(exception, extra: { hearing_id: virtual_hearing.hearing_id })
  end

  def perform(hearing_id:)
    @virtual_hearing = VirtualHearing.where(hearing_id: hearing_id).order(created_at: :desc).first

    virtual_hearing.establishment.attempted!

    create_conference if !virtual_hearing.conference_id && !virtual_hearing.alias

    VirtualHearings::SendEmail.new(virtual_hearing: virtual_hearing, type: :confirmation).call

    if virtual_hearing.active? && virtual_hearing.all_emails_sent?
      virtual_hearing.establishment.clear_error!
      virtual_hearing.establishment.processed!
    end
  end

  private

  def create_conference
    assign_virtual_hearing_alias_and_pins if should_initialize_alias_and_pins?

    resp = client.create_conference(
      host_pin: virtual_hearing.host_pin,
      guest_pin: virtual_hearing.guest_pin,
      name: virtual_hearing.alias
    )

    if resp.error
      Rails.logger.warn "CreateConferenceJob failed: #{resp.error.message}"

      virtual_hearing.establishment.update_error!(resp.error.message)

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
