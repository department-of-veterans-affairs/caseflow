# frozen_string_literal: true

describe HearingsProfileMailer do
  let(:send_to_email_address) { "ann.gibson@example.com" }
  let(:body_json) do
    {
      profile: {
        current_user_css_id: "SAMPLE",
        current_user_timezone: "America/Los_Angeles",
        time_zone_name: "America/Los_Angeles",
        config_time_zone: "UTC"
      },
      hearings: {
        ama_hearings: [
          {
            id: 1,
            type: "Hearing",
            external_id: "fake-external-id",
            created_by_timezone: "America/New_York",
            central_office_time_string: "11:30",
            scheduled_time_string: "08:30",
            scheduled_for: "2020-03-19T11:30:00.000-05:00",
            scheduled_time: "2000-01-01T11:30:00.000-05:00"
          }
        ],
        legacy_hearings: [
          {
            id: 1,
            type: "LegacyHearing",
            external_id: "123456",
            created_by_timezone: "America/New_York",
            central_office_time_string: "10:00",
            scheduled_time_string: "10:00",
            scheduled_for: "2020-02-19T10:00:00.000-05:00",
            scheduled_time: "2000-01-01T15:00:00.000Z"
          }
        ]
      }
    }.to_json
  end

  before do
    Timecop.freeze(Time.utc(2020, 3, 4, 14, 23, 0))
  end

  subject do
    HearingsProfileMailer.call(email_address: send_to_email_address, mail_body: body_json)
  end

  it "delivers an email" do
    expect { subject.deliver_now }.to change { ActionMailer::Base.deliveries.count }.by 1
  end

  it "creates an email to the expected address with the expected subject and body" do
    expect(subject.to).to eq [send_to_email_address]
    expect(subject.subject).to eq "Hearings profile results on #{Time.zone.now.strftime('%b %-d at %H:%M')}"
    expect(subject.body.raw_source).to eq body_json
  end
end
