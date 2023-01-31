# frozen_string_literal: true

describe MembershipMailer do
  let(:email_recipient_info) { create(:user) }
  let(:email) {"lianna.newman@va.gov"}
  let(:name) {'Lianna'}
  let(:subject) { "Membership request submitted." }

  context "with recipient_info" do

    describe "membership_request_submitted" do
      subject { MembershipMailer.membership_request_submitted(email_recipient_info: email_recipient_info) }

      it "has the correct From email address" do
        expect(subject.from).to include("BoardofVeteransAppealsHearings@messages.va.gov")
      end

      it "has the correct subject line" do
        expect(subject).to eq(subject)
      end

      # it "sends an email confirming membership request submitted successfully" do
      #   subject_to = subject.to(email)
      #   expect(subject_to.deliver_now).to change {
      #   ActionMailer::Base.deliveries.count }.by 1
      # end
    end

    describe "updated_membership_request_status" do
      subject { MembershipMailer.updated_membership_request_status(email_recipient_info: email_recipient_info) }
      it "has the correct From address" do
        expect(subject.from).to include('BoardofVeteransAppealsHearings@messages.va.gov')
      end

      it "has the correct subject line" do
        expect(subject).to eq(subject)
      end

      # it "sends a status update email to requestor" do
      #   expect(subject.deliver_now!).to change {
      #   ActionMailer::Base.deliveries.count }.by 1
      # end
    end

    describe "membership_request_submission" do
      subject { MembershipMailer.membership_request_submission(email_recipient_info: email_recipient_info) }

      it "has the correct From email address" do
        expect(subject.from).to include("BoardofVeteransAppealsHearings@messages.va.gov")
      end

      # it "sends an email to admins" do
      #   expect(subject.deliver_now!).to change {
      #   ActionMailer::Base.deliveries.count }.by 1
      # end

      it "has the correct subject line" do

        expect(subject).to eq(subject)
      end

    end
  end
end

