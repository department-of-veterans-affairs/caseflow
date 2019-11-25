# frozen_string_literal: true

RSpec.feature "Send feedback", :all_dbs do
  let!(:current_user) { User.authenticate! }
  let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

  scenario "Sending feedback about Caseflow Certification" do
    visit "certifications/new/#{appeal.vacols_id}"

    expect(page).to have_link("Send feedback")

    href = find_link("Send feedback")["href"]
    expect(href).to match(/\/feedback$/)
  end
end
