require "rails_helper"

RSpec.feature "Send feedback" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
    reset_application!
    Fakes::AppealRepository.records = { "ABCD" => Fakes::AppealRepository.appeal_ready_to_certify }
  end
  after { Timecop.return }

  scenario "Sending feedback about certification", focus: true do
    User.authenticate!

    visit "certifications/new/ABCD"
    href = ""
    expect(page).to have_link("Send feedback", href: ENV["CASEFLOW_FEEDBACK_DOMAIN"] + '?')
  end
end
