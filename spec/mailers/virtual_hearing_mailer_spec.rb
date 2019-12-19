# frozen_string_literal: true

describe VirtualHearingMailer do
  let(:title) { MailRecipient::RECIPIENT_TITLES[:judge] }
  let(:hearing) { build(:hearing, hearing_location: HearingLocation.create) }
  let(:virtual_hearing) { build(:virtual_hearing, hearing: hearing) }
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
