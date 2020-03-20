# frozen_string_literal: true

describe VirtualHearingMailer do
  let(:nyc_ro_eastern) { "RO06" }
  let(:oakland_ro_pacific) { "RO43" }
  let(:regional_office) { nil }
  let(:hearing_day) do
    create(
      :hearing_day,
      request_type: HearingDay::REQUEST_TYPES[:video],
      regional_office: regional_office
    )
  end
  let(:virtual_hearing) { create(:virtual_hearing, hearing: hearing) }
  let(:recipient_title) { nil }
  let(:recipient) { MailRecipient.new(name: "LastName", email: "email@test.com", title: recipient_title) }

  shared_context "ama hearing" do
    let(:hearing) do
      create(
        :hearing,
        scheduled_time: "8:30AM",
        hearing_day: hearing_day,
        regional_office: regional_office
      )
    end
  end

  shared_context "legacy hearing" do
    let(:hearing) do
      hearing_date = Time.use_zone("America/New_York") { Time.zone.now.change(hour: 11, min: 30) }
      case_hearing = create(
        :case_hearing,
        hearing_type: hearing_day.request_type,
        hearing_date: VacolsHelper.format_datetime_with_utc_timezone(hearing_date) # VACOLS always has EST time
      )

      create(
        :legacy_hearing,
        case_hearing: case_hearing,
        hearing_day: hearing_day,
        hearing_day_id: hearing_day.id
      )
    end
  end

  before do
    # Freeze the time to when this fix is made to workaround a potential DST bug.
    Timecop.freeze(Time.utc(2020, 1, 20, 16, 50, 0))
  end

  shared_examples_for "sends all email types" do
    let(:regional_office) { nyc_ro_eastern }

    describe "#cancellation" do
      it "sends a cancellation email" do
        expect do
          VirtualHearingMailer.cancellation(
            mail_recipient: recipient,
            virtual_hearing: virtual_hearing
          ).deliver_now
        end
          .to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    describe "#confirmation" do
      it "sends a confirmation email" do
        expect do
          VirtualHearingMailer.confirmation(
            mail_recipient: recipient,
            virtual_hearing: virtual_hearing
          ).deliver_now
        end
          .to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    describe "#updated_time_confirmation" do
      it "sends a confirmation email" do
        expect do
          VirtualHearingMailer.updated_time_confirmation(
            mail_recipient: recipient,
            virtual_hearing: virtual_hearing
          ).deliver_now
        end
          .to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end

  shared_examples_for "email body has the right times" do |expected_eastern, expected_pacific|
    subject { VirtualHearingMailer.confirmation(mail_recipient: recipient, virtual_hearing: virtual_hearing) }

    context "regional office is in eastern timezone" do
      let(:regional_office) { nyc_ro_eastern }

      it "has the correct time in the confirmation email" do
        expect(subject.html_part.body).to include(expected_eastern)
      end
    end

    context "regional office is in pacific timezone" do
      let(:regional_office) { oakland_ro_pacific }

      it "has the correct time in the confirmation email" do
        expect(subject.html_part.body).to include(expected_pacific)
      end
    end
  end

  # ama_times & legacy_times are in the format { expected_eastern: "10:30 EST", expected_pacific: "7:30 PST" }
  # expected_eastern is the time displayed in the email body when the regional office is in the eastern time zone
  # expected_pacific is the time displayed in the email body when the regional office is in the pacific time zone
  shared_examples_for "email body has the right times with ama and legacy hearings" do |ama_times, legacy_times|
    context "with ama hearing" do
      include_context "ama hearing"

      it_behaves_like(
        "email body has the right times", ama_times[:expected_eastern], ama_times[:expected_pacific]
      )
    end

    context "with legacy hearing" do
      include_context "legacy hearing"

      it_behaves_like(
        "email body has the right times", legacy_times[:expected_eastern], legacy_times[:expected_pacific]
      )
    end
  end

  context "for judge" do
    include_context "ama hearing"

    let(:recipient_title) { MailRecipient::RECIPIENT_TITLES[:judge] }

    it_behaves_like "sends all email types"

    # we expect the judge to always see the hearing time in central office (eastern) time zone

    # ama hearing is scheduled at 8:30am in the regional office's time zone
    expected_ama_times = { expected_eastern: "8:30am EST", expected_pacific: "11:30am EST" }
    # legacy hearing is scheduled at 11:30am in the central office's time zone (eastern)
    expected_legacy_times = { expected_eastern: "11:30am EST", expected_pacific: "11:30am EST" }
    it_behaves_like(
      "email body has the right times with ama and legacy hearings", expected_ama_times, expected_legacy_times
    )
  end

  context "for veteran" do
    include_context "ama hearing"

    let(:recipient_title) { MailRecipient::RECIPIENT_TITLES[:veteran] }

    it_behaves_like "sends all email types"

    # we expect the veteran to always see the hearing time in the regional office time zone

    # ama hearing is scheduled at 8:30am in the regional office's time zone
    expected_ama_times = { expected_eastern: "8:30am EST", expected_pacific: "8:30am PST" }
    # legacy hearing is scheduled at 11:30am in the central office's time zone (eastern)
    expected_legacy_times = { expected_eastern: "11:30am EST", expected_pacific: "8:30am PST" }
    it_behaves_like(
      "email body has the right times with ama and legacy hearings", expected_ama_times, expected_legacy_times
    )
  end

  context "for representative" do
    include_context "ama hearing"

    let(:recipient_title) { MailRecipient::RECIPIENT_TITLES[:representative] }

    it_behaves_like "sends all email types"
  end
end
