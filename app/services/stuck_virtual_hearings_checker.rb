# frozen_string_literal: true

# Data integrity checker for notifying when a virtual hearing is 'stuck'
# i.e the pexip conference creation is pending and/or all emails haven't successfuly sent
class StuckVirtualHearingsChecker < DataIntegrityChecker
  def call
    build_report(stuck_virtual_hearings)
  end

  # sending to appeals-tango for now, might later change to #appeals-hearings
  def slack_channel
    "#appeals-tango"
  end

  private

  TRACKING_DOCUMENT = "https://hackmd.io/DKPyLFB7QHuw6JuuTfc_8A"

  def stuck_virtual_hearings
    rerun_jobs

    VirtualHearingRepository.with_pending_conference_or_emails.select do |virtual_hearing|
      virtual_hearing.updated_at < Time.zone.now - 2.hours
    end
  end

  def build_report(stuck_virtual_hearings)
    return if stuck_virtual_hearings.empty?

    stuck_count = stuck_virtual_hearings.count

    add_to_report "Found #{stuck_count} stuck #{'virtual hearing'.pluralize(stuck_count)}: "
    stuck_virtual_hearings.each do |stuck_vh|
      add_to_report "`VirtualHearing.find(#{stuck_vh.id})` " \
        "last attempted at: #{stuck_vh.establishment.attempted_at}, " \
        "scheduled for: #{stuck_vh.hearing.scheduled_for}, updated by: #{stuck_vh.updated_by.css_id}, " \
        "#{uuid_or_vacols_id_of_hearing(stuck_vh)}"
    end

    add_to_report "If a virtual hearing is in this state, Caseflow may not be displaying the information that " \
      "users need to prepare for the hearing, and notification emails may not have been sent."
    add_to_report "Stuck virtual hearings are tracked in this document: " \
      "#{TRACKING_DOCUMENT}"
  end

  def uuid_or_vacols_id_of_hearing(virtual_hearing)
    if virtual_hearing.hearing.is_a? Hearing
      "UUID: #{virtual_hearing.hearing.uuid}"
    elsif virtual_hearing.hearing.is_a? LegacyHearing
      "VACOLS ID: #{virtual_hearing.hearing.vacols_id}"
    end
  end

  # rerun jobs for those virtual hearings never got run
  def rerun_jobs
    VirtualHearing
      .where(conference_id: nil)
      .pluck(:hearing_id, :hearing_type)
      .each do |hearing_id, hearing_type|
        VirtualHearings::CreateConferenceJob.perform_now(hearing_id: hearing_id, hearing_type: hearing_type)
      end
  end
end
