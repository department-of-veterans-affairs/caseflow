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
    @virtual_hearing = VirtualHearing.find_by(hearing_id: hearing_id)

    if !virtual_hearing.conference_id && !virtual_hearing.alias
      assign_virtual_hearing_alias

      resp = client.create_conference(
        host_pin: rand(1000..9999),
        guest_pin: rand(1000..9999),
        name: virtual_hearing.alias
      )

      if resp.error
        Rails.logger.info "CreateConferenceJob failed: #{resp.error.message}"
        fail resp.error
      end

      virtual_hearing.update(conference_id: resp.data[:conference_id], status: :active)
    end

    VirtualHearings::SendEmail.new(virtual_hearing: virtual_hearing, type: :confirmation).call
  end

  private

  def assign_virtual_hearing_alias
    # Using pessimistic locking here because no other processes should be reading
    # the record while maximum is being calculated.
    virtual_hearing.with_lock do
      max_alias = VirtualHearing.maximum(:alias)
      conference_alias = max_alias ? (max_alias.to_i + 1).rjust(7, "0") : "0000001"
      virtual_hearing.alias = conference_alias.to_s
      virtual_hearing.save!
    end
  end
end
