# frozen_string_literal: true

describe VirtualHearingMailer do
  # New York City regional office
  let(:regional_office) { "RO06" }
  let(:hearing_day) do
    create(
      :hearing_day,
      request_type: HearingDay::REQUEST_TYPES[:video],
      regional_office: regional_office
    )
  end
  let(:hearing) do
    create(
      :hearing,
      scheduled_time: "10:30AM",
      hearing_day: hearing_day,
      regional_office: regional_office
    )
  end
  let(:virtual_hearing) { create(:virtual_hearing, hearing: hearing) }
  let(:title) { nil }

  before do
    # Freeze the time to when this fix is made to workaround a potential DST bug.
    Timecop.freeze(Time.utc(2020, 1, 20, 16, 50, 0))
  end

  shared_examples_for "it can send an email to a recipient with the title" do
    let(:recipient) { MailRecipient.new(name: "LastName", email: "email@test.com", title: title) }

    describe "#cancellation" do
      it "sends a cancellation email" do
        expect do
          VirtualHearingMailer.cancellation(mail_recipient: recipient, virtual_hearing: virtual_hearing).deliver_now
        end
          .to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    describe "#confirmation" do
      it "sends a confirmation email" do
        expect do
          VirtualHearingMailer.confirmation(mail_recipient: recipient, virtual_hearing: virtual_hearing).deliver_now
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

  context "for judge" do
    let(:title) { MailRecipient::RECIPIENT_TITLES[:judge] }

    it_should_behave_like "it can send an email to a recipient with the title"
  end

  context "for veteran" do
    let(:title) { MailRecipient::RECIPIENT_TITLES[:veteran] }
    let(:recipient) { MailRecipient.new(name: "LastName", email: "veteran@test.com", title: title) }

    it_should_behave_like "it can send an email to a recipient with the title"

    subject do
      VirtualHearingMailer.confirmation(
        mail_recipient: recipient,
        virtual_hearing: virtual_hearing
      )
    end

    shared_examples_for "it has the correct time in the email body" do |expected_est_time, expected_pst_time|
      context "on east coast" do
        it "has the correct time in the confirmation email" do
          expect(subject.html_part.body).to include("#{expected_est_time} EST")
        end
      end

      context "on west coast" do
        # Oakland, CA Regional Office
        let(:regional_office) { "RO43" }

        it "has the correct time in the confirmation email" do
          expect(subject.html_part.body).to include("#{expected_pst_time} PST")
        end
      end
    end

    context "with ama hearing" do
      it_should_behave_like "it has the correct time in the email body", "10:30am", "10:30am"
    end

    context "with legacy hearing" do
      let(:case_hearing) do
        hearing_date = Time.use_zone("America/New_York") { Time.zone.now.change(hour: 10, min: 30) }

        create(
          :case_hearing,
          hearing_type: hearing_day.request_type,
          hearing_date: VacolsHelper.format_datetime_with_utc_timezone(hearing_date) # VACOLS always has EST time
        )
      end
      let(:hearing) do
        create(
          :legacy_hearing,
          case_hearing: case_hearing,
          hearing_day: hearing_day,
          hearing_day_id: hearing_day.id
        )
      end

      it_should_behave_like "it has the correct time in the email body", "10:30am", "7:30am"
    end
  end

  context "for representative" do
    let(:title) { MailRecipient::RECIPIENT_TITLES[:representative] }

    it_should_behave_like "it can send an email to a recipient with the title"
  end
end
