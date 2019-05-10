# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Send feedback" do
  let!(:current_user) { User.authenticate! }
  let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

  scenario "Sending feedback about Caseflow Certification" do
    visit "certifications/new/#{appeal.vacols_id}"

    expect(page).to have_link("Send feedback")
    click_on "Send feedback"
    expect(page).to have_content("YourIT")
  end
end
