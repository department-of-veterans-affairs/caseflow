# frozen_string_literal: true

describe VirtualHearingMailer do
  let(:regional_office) { "RO06" }
  let(:hearing_day) { build(:hearing_day, regional_office: regional_office) }
  let(:hearing) do
    build(
      :hearing,
      scheduled_time: "6:30PM", # This time is in UTC
      hearing_day: hearing_day,
      regional_office: regional_office
    )
  end
  let(:virtual_hearing) { build(:virtual_hearing, hearing: hearing) }

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

    context "on east coast" do
      it "has the correct time in the confirmation email" do
        expect(subject.html_part.body).to include("1:30pm EST")
      end
    end

    context "on west coast" do
      # Oakland, CA Regional Office
      let(:regional_office) { "RO43" }

      it "has the correct time in the confirmation email" do
        expect(subject.html_part.body).to include("10:30am PST")
      end
    end
  end

  context "for representative" do
    let(:title) { MailRecipient::RECIPIENT_TITLES[:representative] }

    it_should_behave_like "it can send an email to a recipient with the title"
  end
end
