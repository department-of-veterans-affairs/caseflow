# frozen_string_literal: true

# Data integrity checker for notifying when a virtual hearing is 'stuck'
# i.e the pexip conference creation is pending and/or all emails haven't successfuly sent
class StuckVirtualHearingsChecker < DataIntegrityChecker
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper

  def call
    build_report(stuck_virtual_hearings)
  end

  # sending to appeals-tango for now, might later change to #appeals-hearings
  def slack_channel
    "#appeals-tango"
  end

  private

  TRACKING_DOCUMENT_LINK = "https://hackmd.io/DKPyLFB7QHuw6JuuTfc_8A"

  def stuck_virtual_hearings
    @stuck_virtual_hearings ||= begin
      rerun_jobs

      # select hearings with pending conference/emails updated earlier than 2 hours ago, scheduled today or later
      virtual_hearings = VirtualHearingRepository.with_pending_conference_or_emails.select do |virtual_hearing|
        virtual_hearing.updated_at < 2.hours.ago &&
          virtual_hearing.hearing.scheduled_for > 1.day.ago
      end

      # sort hearings that are happening sooner to the top
      virtual_hearings.sort_by { |virtual_hearing| virtual_hearing.hearing.scheduled_for }
    end
  end

  def build_report(stuck_virtual_hearings)
    return if stuck_virtual_hearings.empty?

    stuck_count = stuck_virtual_hearings.count

    add_to_report "Found #{stuck_count} stuck #{'virtual hearing'.pluralize(stuck_count)}: "
    stuck_virtual_hearings.each do |stuck_vh|
      add_to_report "`VirtualHearing.find(#{stuck_vh.id})` " \
        "last attempted: #{last_attempted_report(stuck_vh)}, " \
        "#{scheduled_for_report(stuck_vh)}, " \
        "updated by: #{stuck_vh.updated_by.css_id}, " \
        "#{external_id_report(stuck_vh)}"
    end

    add_to_report "If a virtual hearing is in this state, Caseflow may not be displaying the information that " \
      "users need to prepare for the hearing, and notification emails may not have been sent."
    add_to_report "Stuck virtual hearings are tracked in *<#{TRACKING_DOCUMENT_LINK}|this document>*."
  end

  def last_attempted_report(virtual_hearing)
    if virtual_hearing.establishment.attempted_at.present?
      "#{time_ago_in_words(virtual_hearing.establishment.attempted_at)} ago"
    else
      "never"
    end
  end

  def scheduled_for_report(virtual_hearing)
    scheduled_for = virtual_hearing.hearing.scheduled_for
    "scheduled for: #{scheduled_for.strftime('%a %m/%d')} #{display_in_words(scheduled_for)}"
  end

  def display_in_words(scheduled_for)
    in_words = time_ago_in_words(scheduled_for)
    if Time.zone.now < scheduled_for
      "(in #{in_words})"
    else
      "(#{in_words} ago)"
    end
  end

  def external_id_report(virtual_hearing)
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
        begin
          VirtualHearings::CreateConferenceJob.perform_now(hearing_id: hearing_id, hearing_type: hearing_type)
        rescue VirtualHearings::SendEmail::RecipientIsDeceasedVeteran
          next
        end
      end
  end
end
