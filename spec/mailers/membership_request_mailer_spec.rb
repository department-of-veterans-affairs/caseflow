# frozen_string_literal: true

describe MembershipRequestMailer do
  let(:email_recipient_info) { { email: email } }
  let(:email) { "bob.schmidt@va.gov" }
  let(:name) { "Bob" }
  let(:subject) { { custom_subject: custom_subject } }

  context "with recipient_info" do
    describe "membership_request_submitted" do
      let(:mailer) { MembershipRequestMailer.membership_request_submitted(email_recipient_info: email_recipient_info) }

      it "has the correct From email address" do
        expect(mailer.from).to include("BoardofVeteransAppealsHearings@messages.va.gov")
      end

      it "has the correct subject line" do
        expect(mailer.subject).to eq("Membership request submitted.")
      end
    end

    describe "updated_membership_request_status" do
      let(:mailer) { MembershipRequestMailer.updated_membership_request_status(email_recipient_info: email_recipient_info) }

      it "has the correct From address" do
        expect(mailer.from).to include("BoardofVeteransAppealsHearings@messages.va.gov")
      end

      it "has the correct subject line" do
        expect(mailer.subject).to eq("Membership request status updated.")
      end
    end

    describe "membership_request_submission" do
      let(:mailer) { MembershipRequestMailer.membership_request_submission(email_recipient_info: email_recipient_info) }

      it "has the correct From email address" do
        expect(mailer.from).to include("BoardofVeteransAppealsHearings@messages.va.gov")
      end

      it "has the correct subject line" do
        expect(mailer.subject).to eq("New membership request recieved.")
      end
    end
  end
end
