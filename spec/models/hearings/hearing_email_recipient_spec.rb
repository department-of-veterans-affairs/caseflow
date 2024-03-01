# frozen_string_literal: true

describe HearingEmailRecipient do
  # Load all models (for HearingEmailRecipient subclasses) and execute block for each subclass...
  Dir[Rails.root.join("app/models/**/*.rb")].sort.each { |f| require f }
  described_class.descendants.each do |hearing_email_recipient_subclass|
    context hearing_email_recipient_subclass.to_s do
      it_behaves_like "HearingEmailRecipient belongs_to polymorphic appeal", hearing_email_recipient_subclass
      it_behaves_like "HearingEmailRecipient belongs_to polymorphic hearing", hearing_email_recipient_subclass
    end
  end

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
              "#{error_title} email does not appear to be a valid e-mail address")
        end
      end

      context "nil email validation" do
        let(:email_address) { nil }

        it "raises an error when email is nil" do
          expect { subject }
            .to raise_error(ActiveRecord::RecordInvalid)
            .with_message(
              /Validation failed: Email address can't be blank/
            )
        end
      end
    end

    context "AppellantHearingEmailRecipient" do
      let(:type) { AppellantHearingEmailRecipient.name }
      let(:error_title) { HearingEmailRecipient::RECIPIENT_TITLES[:appellant] }

      include_context "shared behaviors"
    end

    context "RepresentativeHearingEmailRecipient" do
      let(:type) { RepresentativeHearingEmailRecipient.name }
      let(:error_title) { HearingEmailRecipient::RECIPIENT_TITLES[:representative] }

      include_context "shared behaviors"
    end

    context "JudgeHearingEmailRecipient" do
      let(:type) { JudgeHearingEmailRecipient.name }
      let(:error_title) { HearingEmailRecipient::RECIPIENT_TITLES[:judge] }

      include_context "shared behaviors"
    end
  end

  context "#email_error_message" do
    subject { described_class.email_error_message }

    it "raises an error" do
      expect { subject }.to raise_error(Caseflow::Error::MustImplementInSubclass)
    end
  end

  context "#roles" do
    let(:email_recipient) { nil }
    subject { email_recipient.roles }

    context "HearingEmailRecipient" do
      let(:email_recipient) do
        create(:hearing_email_recipient)
      end

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MustImplementInSubclass)
      end
    end

    context "AppellantHearingEmailRecipient" do
      let(:email_recipient) do
        create(
          :hearing_email_recipient,
          :initialized,
          :appellant_hearing_email_recipient
        )
      end
      let(:roles) do
        [
          HearingEmailRecipient::RECIPIENT_ROLES[:appellant],
          HearingEmailRecipient::RECIPIENT_ROLES[:veteran]
        ]
      end

      it "returns correct value" do
        expect(subject).to eq(roles)
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
      let(:roles) { [HearingEmailRecipient::RECIPIENT_ROLES[:representative]] }

      it "returns correct value" do
        expect(subject).to eq(roles)
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
      let(:roles) { [HearingEmailRecipient::RECIPIENT_ROLES[:judge]] }

      it "returns correct value" do
        expect(subject).to eq(roles)
      end
    end
  end

  context "#reminder_sent_at" do
    let(:email_recipient) do
      create(
        :hearing_email_recipient,
        :initialized,
        :appellant_hearing_email_recipient
      )
    end

    subject { email_recipient.reload.reminder_sent_at }

    context "there exists a reminder email event" do
      let!(:reminder_event) do
        create(
          :sent_hearing_email_event,
          :reminder,
          recipient_role: HearingEmailRecipient::RECIPIENT_ROLES[:veteran],
          sent_at: Time.zone.now - 3.days,
          email_recipient: email_recipient
        )
      end

      it "returns correct value" do
        expect(subject).to(
          be_within(1.second).of(reminder_event.sent_at)
        )
      end
    end

    context "no reminder email event is present" do
      it "returns correct value" do
        expect(subject).to eq(nil)
      end
    end
  end

  context "#unset_email_address!" do
    let(:email_recipient) { nil }
    subject { email_recipient.unset_email_address! }

    context "RepresentativeHearingEmailRecipient" do
      let(:email_recipient) do
        create(
          :hearing_email_recipient,
          :initialized,
          :representative_hearing_email_recipient
        )
      end

      it "unsets the email address" do
        expect(email_recipient.email_address).to_not be_nil
        subject
        expect(email_recipient.email_address).to be_nil
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

      it "unsets the email address" do
        expect(email_recipient.email_address).to_not be_nil
        subject
        expect(email_recipient.email_address).to be_nil
      end
    end
  end
end
