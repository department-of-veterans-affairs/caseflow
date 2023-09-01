# frozen_string_literal: true

class DeleteConferenceLinkJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    links_for_past_date = retreive_stale_conference_links
    soft_delete_links(links_for_past_date)
  end

  private

  def retreive_stale_conference_links
    ConferenceLink.joins(:hearing_day).where("scheduled_for < ?", Date.today)
  end

  def soft_delete_links(collection)
    collection.each do |old_link|
      old_link.update!(update_conf_links)
    end
  end

  def update_conf_links
    {
      conference_deleted: true,
      updated_by_id: RequestStore[:current_user],
      updated_at: Time.zone.now,
      guest_hearing_link: nil,
      # guest_pin: nil,
      guest_pin_long: nil,
      host_link: nil,
      host_pin: nil,
      host_pin_long: nil
    }
  end

  # TODO Create a Hearing Day scheduled in the future. Given that the link is created, that would allow me to test the job and see how many it receives.
end
