require "rails_helper"

RSpec.feature "Send feedback" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
    reset_application!
    Fakes::AppealRepository.records = { "ABCD" => Fakes::AppealRepository.appeal_ready_to_certify }
  end
  after { Timecop.return }

  scenario "Sending feedback about Caseflow Certification" do
      User.authenticate!
      visit "certifications/new/ABCD"

      expect(page).to have_link("Send feedback")

      href = find_link("Send feedback")["href"]
      expect(find_link("Send feedback")["href"].include? ENV["CASEFLOW_FEEDBACK_URL"]).to be true
      expect(find_link("Send feedback")["href"].include? "subject=Caseflow+Certification").to be true
      expect(find_link("Send feedback")["href"].include? "redirect=").to be true
  end
end
