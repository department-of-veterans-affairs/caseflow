# frozen_string_literal: true

# Data integrity checker for notifying when a virtual hearing is 'stuck'
# i.e the pexip conference creation is pending and/or all emails haven't successfuly sent
class StuckVirtualHearingsChecker < DataIntegrityChecker
  def call
    build_report(stuck_virtual_hearings)
  end

  def stuck_virtual_hearings
    VirtualHearingRepository.hearings_with_pending_conference_or_emails.select do |virtual_hearing|
      virtual_hearing.updated_at < Time.zone.now - 2.hours
    end
  end

  # sending to appeals-tango for now, might later change to #appeals-hearings
  def slack_channel
    "#appeals-tango"
  end

  def build_report(stuck_virtual_hearings)
    return if stuck_virtual_hearings.empty?

    stuck_count = stuck_virtual_hearings.count

    add_to_report "Found #{stuck_count} stuck #{(stuck_count > 1) ? 'virtual hearings' : 'virtual hearing'}: "
    stuck_virtual_hearings.each do |stuck_vh|
      add_to_report "VirtualHearing.find(#{stuck_vh.id}) last processed at #{stuck_vh.establishment.processed_at}"
    end
  end
end
