# frozen_string_literal: true

describe HearingEmailRecipient do
  context "#create" do
    let(:hearing) { create(:hearing) }
    let(:email_address) { "test@email.com" }
    let(:timezone) { "America/New_York" }
    let(:type) { nil }

    subject do
      HearingEmailRecipient.create!(
        type: type,
        email_address: email_address,
        timezone: timezone,
        hearing: hearing
      )
    end

    shared_context "shared behaviors" do
      it "creates with right values", :aggregate_failures do
        expect(subject.role).to eq(role)
        expect(subject.email_sent).to eq(false)
        expect(subject.email_address).to eq(email_address)
        expect(subject.timezone).to eq(timezone)
        expect(subject.hearing).to eq(hearing)
      end

      context "invalid email validation" do
        let(:email_address) { "blah" }

        it "raises an error when email is invalid" do
          expect { subject }
            .to raise_error(ActiveRecord::RecordInvalid)
            .with_message("Validation failed: Email address Validation failed: " \
              "#{error_title} email does not appear to be a valid e-mail address"
            )
        end
      end
    end

    context "AppellantHearingEmailRecipient" do
      let(:type) { AppellantHearingEmailRecipient.name }
      let(:role) { "veteran" }
      let(:error_title) { HearingEmailRecipient::RECIPIENT_TITLES[:appellant] }

      include_context "shared behaviors"

      context "nil email validation" do
        let(:email_address) { nil }

        it "raises an error when email is nil" do
          expect { subject }
            .to raise_error(ActiveRecord::RecordInvalid)
            .with_message(
              "Validation failed: Email address can't be blank, Email address Validation failed: " \
              "#{error_title} email does not appear to be a valid e-mail address"
            )
        end
      end
    end

    context "RepresentativeHearingEmailRecipient" do
      let(:type) { RepresentativeHearingEmailRecipient.name }
      let(:role) { HearingEmailRecipient::RECIPIENT_ROLES[:representative] }
      let(:error_title) { HearingEmailRecipient::RECIPIENT_TITLES[:representative] }

      include_context "shared behaviors"
    end

    context "JudgeHearingEmailRecipient" do
      let(:type) { JudgeHearingEmailRecipient.name }
      let(:role) { HearingEmailRecipient::RECIPIENT_ROLES[:judge] }
      let(:error_title) { HearingEmailRecipient::RECIPIENT_TITLES[:judge] }

      include_context "shared behaviors"
    end
  end

  context "#role" do
    let(:email_recipient) { nil }
    subject { email_recipient.role }

    context "AppellantHearingEmailRecipient" do
      let(:email_recipient) do
        create(
          :hearing_email_recipient,
          :initialized,
          :appellant_hearing_email_recipient
        )
      end
      let(:role) { "veteran" }

      it "returns correct value" do
        expect(subject).to eq(role)
      end
    end

    context "RepresentativeHearingEmailRecipient" do
      let(:email_recipient) do
        create(
          :hearing_email_recipient,
          :initialized,
          :representative_hearing_email_recipient
        )
      end
      let(:role) { HearingEmailRecipient::RECIPIENT_ROLES[:representative] }

      it "returns correct value" do
        expect(subject).to eq(role)
      end
    end

    context "JudgeHearingEmailRecipient" do
      let(:email_recipient) do
        create(
          :hearing_email_recipient,
          :initialized,
          :judge_hearing_email_recipient
        )
      end
      let(:role) { HearingEmailRecipient::RECIPIENT_ROLES[:judge] }

      it "returns correct value" do
        expect(subject).to eq(role)
      end
    end
  end

  context "#reminder_sent_at" do
    let!(:reminder_sent_at) { Time.zone.now - 3.days }
    let(:email_recipient) do
      create(
        :hearing_email_recipient,
        :initialized,
        :appellant_hearing_email_recipient
      )
    end

    subject { email_recipient.reminder_sent_at }

    context "there exists a reminder email event" do
      let!(:reminder_event) do
        create(
          :sent_hearing_email_event,
          :reminder,
          sent_at: reminder_sent_at,
          email_recipient: email_recipient
        )
      end

      it "returns correct value" do
        expect(subject).to eq(reminder_sent_at)
      end
    end

    context "no reminder email event is present" do
      it "returns correct value" do
        expect(subject).to eq(nil)
      end
    end
  end
end
