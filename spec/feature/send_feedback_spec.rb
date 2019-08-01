# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

RSpec.feature "Send feedback", :all_dbs do
  let!(:current_user) { User.authenticate! }
  let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

  scenario "Sending feedback about Caseflow Certification" do
    visit "certifications/new/#{appeal.vacols_id}"

    expect(page).to have_link("Send feedback")

    href = find_link("Send feedback")["href"]
    expect(href).to match(/\/feedback$/)
  end

  context "User is part of VSO" do
    before do
      allow(current_user).to receive(:vso_employee?) { true }
    end

    scenario "Can see Feedback page" do
      visit "/feedback"

      expect(page).to have_content("YourIT")
    end
  end
end
