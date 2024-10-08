# frozen_string_literal: true

require_relative "../../../app/services/claim_change_history/change_history_reporter.rb"
require_relative "../../../app/services/claim_change_history/claim_history_service.rb"
require_relative "../../../app/services/claim_change_history/claim_history_event.rb"
require_relative "../../../app/services/claim_change_history/change_history_filter_parser.rb"
require_relative "../../../app/services/claim_change_history/change_history_event_serializer.rb"

feature "Individual Claim History", :postgres do
  let(:non_comp_org) { VhaBusinessLine.singleton }
  let(:user) { create(:default_user, css_id: "REPORT USER", full_name: "Report User") }
  let(:veteran) { create(:veteran) }
  let!(:task) { create(:higher_level_review_vha_task_with_decision) }
  let(:task_history_url) { "/decision_reviews/vha/tasks/#{task.id}/history" }
  let(:events) { ClaimHistoryService.new(non_comp_org, task_id: task.id).build_events }

  before do
    User.stub = user
    non_comp_org.add_user(user)
    OrganizationsUser.make_user_admin(user, non_comp_org)
    visit task_history_url
  end

  scenario "display the claim history table" do
    number_of_events = events.length

    expect(page).to have_text("Viewing 1-#{number_of_events} of #{number_of_events} total")

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: number_of_events)

    events.each do |event|
      expect(page).to have_text(event.readable_event_type)
    end
  end
end
