# frozen_string_literal: true

RSpec.feature("Correspondence Details Response Letters Module") do
  include CorrespondenceResponseLettersHelpers

  let(:organization) { InboundOpsTeam.singleton }
  let(:bva_user) { User.authenticate!(roles: ["Mail Intake"]) }
  let(:correspondence) { create :correspondence, :with_correspondence_intake_task }
  let(:wait_time) { 40 }

  before(:each) do
    FeatureToggle.enable!(:correspondence_queue)
    organization.add_user(bva_user)
    bva_user.reload
  end

  context "Verifying Correspondence Details Response Letters page" do
    it "Verifies that Response Letters added during Intake are ordered correctly" do
      response_letters_order_actions
      using_wait_time(wait_time) do
        find_by_id("tasks-tabwindow-tab-2").click
        ten_days_before_date = 10.days.ago
        final_date = ten_days_before_date + 2.days
        formatted_date = final_date.strftime("%m/%d/%Y")
        expect(page).to have_content("Expired on #{formatted_date}")
        expect(page).to have_content("No response window required")
        response_letters = page.all(".response-letter-table-borderless-first-item")

        expect(response_letters.size).to be >= 2

        first_element_text = response_letters[0].text
        second_element_text = response_letters[1].text
        expect(first_element_text).to include("Expired on")
        expect(second_element_text).not_to include("Expired on")
      end
    end
  end
end
