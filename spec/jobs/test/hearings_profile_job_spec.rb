# frozen_string_literal: true

describe Test::HearingsProfileJob, :postgres do
  context "#perform" do
    let(:email_address) { "andrea.arnold@example.com" }
    let(:user_css_id) { "VACOARNOLDA" }
    let(:user_timezone) { "America/Los_Angeles" }
    let(:user) { create(:user, email: email_address, css_id: user_css_id) }
    let(:job) { Test::HearingsProfileJob }

    let(:body_json) do
      {
        profile: {
          current_user_css_id: user_css_id,
          current_user_timezone: user_timezone,
          time_zone_name: Time.zone.name,
          config_time_zone: Rails.configuration.time_zone
        },
        hearings: {
          ama_hearings: [],
          legacy_hearings: []
        }
      }.to_json
    end

    subject { job.perform_now(send_to_user: user) }

    it "calls HearingsProfileMailer with the expected arguments" do
      mailer = double(HearingsProfileMailer)

      allow(user).to receive(:timezone).and_return(user_timezone)

      expect(mailer).to receive(:deliver_now).once

      expect(HearingsProfileMailer)
        .to receive(:call)
        .with(email_address: email_address, mail_body: body_json)
        .and_return(mailer)
      subject
    end
  end
end
