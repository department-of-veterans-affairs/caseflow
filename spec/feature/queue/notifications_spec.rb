# frozen_string_literal: true

require "spec_helper"

RSpec.feature "Notifications View" do
  let(:user_roles) { ["System Admin"] }
  before do
    User.authenticate!(roles: user_roles)
    Seeds::NotificationEvents.new.seed!
    notification
  end

  def wait_for_page_render
    # This find forces a wait for the page to render. Without it, a test asserting presence or absence of content
    # may pass whether the content is present or not!
    find("span", class: "cf-push-right")
  end

  context "ama appeal" do
    let(:appeal) do
      create(:appeal)
    end
    let(:notification) do
      create(:notification,
             appeals_id: appeal.uuid,
             appeals_type: "Appeal",
             event_date: Time.zone.today,
             event_type: "Appeal docketed",
             notification_type: "Email",
             notified_at: Time.zone.today,
             email_notification_status: "delivered")
    end

    scenario "admin visits notifications page for ama appeal" do
      visit "queue/appeals/#{appeal.uuid}"
      click_link("View notifications sent to appellant")
    end
  end
end
