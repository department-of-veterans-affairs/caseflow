# frozen_string_literal: true

##
#

class DeleteConferenceLinkJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    begin
      links_for_past_date = retreive_stale_conference_links
      links_soft_removal(links_for_past_date)
    rescue ActiveRecordError => error
      log_error(error)
    end
  end

  private

  # Purpose: Queries the database table of conference_links that are associated with a hearing_day that has already passed.
  #
  # Params: None
  #
  # Return: A collection of links that have passed.
  def retreive_stale_conference_links
    ConferenceLink.joins(:hearing_day).where("scheduled_for < ?", Date.today)
  end

  # Purpose: Iterates through a collection of links, updating each item and then soft_deleting.
  #
  # Params: An array of conference_links.
  #
  # Return: None
  def links_soft_removal(collection)
    collection.each do |old_link|
      # old_link.update!(update_conf_links)
      old_link.destroy
    end
  end

  # Purpose: Updates conference_link attributes when passed into the 'update!' method.
  #
  # Params: None
  #
  # Return: Hash that will update the conference_link
  def update_conf_links
    {
      conference_deleted: true,
      updated_by_id: RequestStore[:current_user],
      updated_at: Time.zone.now,
      guest_hearing_link: nil,
      guest_pin_long: nil,
      host_link: nil,
      host_pin: nil,
      host_pin_long: nil
    }
  end

  # TODO
end
