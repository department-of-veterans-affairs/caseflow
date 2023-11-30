# frozen_string_literal: true

# The DeleteConferenceLinkJob is a job thats collects conference_links from past hearing days.
# It then iterates through that collection and adjusts attribute values for each link.
# Afterwards each link then has `.destroy` called on it to issue a [soft delete].

class VirtualHearings::DeleteConferenceLinkJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    begin
      RequestStore[:current_user] = User.system_user
      retreive_stale_conference_links.each(&:soft_removal_of_link)
    rescue StandardError => error
      log_error(error)
    end
  end

  private

  # Purpose: Queries the DB table of conference_links that are associated with a hearing_day that has already passed.
  #
  # Params: None
  #
  # Return: A collection of links for hearing days that have passed.
  def retreive_stale_conference_links
    ConferenceLink.joins(:hearing_day).where("scheduled_for < ?", Time.zone.today)
  end
end
