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
          config_time_zone: Rails.configuration.time_zone,
          current_user_css_id: user_css_id,
          current_user_timezone: user_timezone,
          time_zone_name: Time.zone.name
        },
        hearings: {
          ama_hearings: [],
          legacy_hearings: []
        }
      }.to_json
    end

    it "calls HearingsProfileMailer with the expected arguments" do
      mailer = double(Test::HearingsProfileMailer)

      allow(user).to receive(:timezone).and_return(user_timezone)

      expect(mailer).to receive(:deliver_now).once

      expect(Test::HearingsProfileMailer)
        .to receive(:call)
        .with(email_address: email_address, mail_body: body_json)
        .and_return(mailer)

      job.perform_now(user)
    end

    context "calls HearingsProfileMailer with a limit over 20" do
      it "calls HearingsProfileHelper with a limit of 20" do
        expect(Test::HearingsProfileHelper)
          .to receive(:profile_data)
          .with(user, limit: 20)

        job.perform_now(user, limit: 100)
      end
    end
  end
end
