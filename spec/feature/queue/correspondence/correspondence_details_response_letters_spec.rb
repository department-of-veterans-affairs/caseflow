# frozen_string_literal: true

RSpec.feature("Correspondence Details Response Letters Module") do
  include CorrespondenceResponseLettersHelpers

  let(:current_user) { create(:user) }
  let(:correspondence) { create :correspondence, :with_correspondence_intake_task }

  context "Verifying Correspondence Details Response Letters page" do
    before(:each) do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user, roles: ["Inbound Ops Team"])
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "Verifies that Response Letters added during Intake are displayed in details page" do
      correspondence = setup_response_letters_data
      using_wait_time(10) do
        visit "/queue/correspondence/#{correspondence.uuid}"
        find_by_id("tasks-tabwindow-tab-2", wait: 10).click
        expect(page).to have_content("Response Letters")
        expect(page).to have_content("No response window required")
        expect(page).to have_content(Time.zone.today.strftime("%m/%d/%Y").to_s)
        expect(page).to have_content("Pre-docketing")
        expect(page).to have_content("Intake 10182 Recv Needs AOJ Development")
        expect(page).to have_content("Issues(s) is VHA")
      end
    end

    it "Verifies that Response Letters added during Intake are ordered correctly" do
      correspondence = response_letters_order_actions
      using_wait_time(10) do
        visit "/queue/correspondence/#{correspondence.uuid}"
        find_by_id("tasks-tabwindow-tab-2", wait: 10).click
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
