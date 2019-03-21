# frozen_string_literal: true

require "rails_helper"

RSpec.feature "List Schedule" do
  context "Correct buttons are displayed based on permissions" do
    let!(:hearing) { create(:hearing) }

    context "Build hearing schedule permissions" do
      let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"]) }

      scenario "All buttons are visible" do
        visit "hearings/schedule"

        expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
        expect(page).to have_content("Schedule Veterans")
        expect(page).to have_content("Build Schedule")
        expect(page).to have_content("Add Hearing Date")
      end
    end

    context "Edit hearing schedule permissions" do
      let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Edit HearSched"]) }

      scenario "Only schedule veterans is available" do
        visit "hearings/schedule"

        expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
        expect(page).to have_content("Schedule Veterans")
        expect(page).to_not have_content("Build Schedule")
        expect(page).to_not have_content("Add Hearing Date")
      end
    end

    context "View hearing schedule permissions" do
      let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["RO ViewHearSched"]) }

      scenario "No buttons are visible" do
        visit "hearings/schedule"

        expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER_RO)
        expect(page).to_not have_content("Schedule Veterans")
        expect(page).to_not have_content("Build Schedule")
        expect(page).to_not have_content("Add Hearing Date")
      end
    end

    context "VSO user view" do
      let!(:current_user) { User.authenticate!(css_id: "VSO_USER", roles: ["VSO"]) }

      scenario "Only hearing days with VSO assigned hearings are displayed" do
        visit "hearings/schedule"
      end
    end
  end
end
