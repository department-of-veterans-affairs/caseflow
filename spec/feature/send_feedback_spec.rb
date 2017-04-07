require "rails_helper"

RSpec.feature "Send feedback" do
  let!(:current_user) { User.authenticate! }
  let(:appeal) { Generators::Appeal.build(vacols_record: :ready_to_certify) }

  scenario "Sending feedback about Caseflow Certification" do
    visit "certifications/new/#{appeal.vacols_id}"

    expect(page).to have_link("Send feedback")

    href = find_link("Send feedback")["href"]
    expect(href.include?(ENV["CASEFLOW_FEEDBACK_URL"])).to be true
    expect(href.include?("subject=Caseflow+Certification")).to be true
    expect(href.include?("redirect=")).to be true
  end
end
