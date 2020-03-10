# frozen_string_literal: true

describe VirtualHearingMailer do
  let(:hearing) { build(:hearing, hearing_location: HearingLocation.create) }
  let(:virtual_hearing) { build(:virtual_hearing, hearing: hearing) }

  shared_examples_for "it can send an email to a recipient with the title" do |title_key|
    let(:title) { MailRecipient::RECIPIENT_TITLES[title_key] }
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

  context "for veteran" do
    it_should_behave_like "it can send an email to a recipient with the title", :veteran
  end

  context "for representative" do
    it_should_behave_like "it can send an email to a recipient with the title", :representative
  end
end
