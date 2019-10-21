# frozen_string_literal: true

require "rails_helper"

describe VirtualHearingMailer do
  let(:title) { VirtualHearingMailer::RECIPIENT_TITLES[:judge] }
  let(:recipient) { MailRecipient.new(full_name: "FirstName LastName", email: "email@test.com", title: title) }

  describe "#cancellation" do
    it "sends a cancellation email" do
      expect { VirtualHearingMailer.cancellation(mail_recipient: recipient).deliver_now }
        .to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end

  describe "#confirmation" do
    it "sends a confirmation email" do
      expect { VirtualHearingMailer.confirmation(mail_recipient: recipient).deliver_now }
        .to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end
