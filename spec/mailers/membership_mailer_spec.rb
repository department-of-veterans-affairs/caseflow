# frozen_string_literal: true

describe MembershipMailer do
  let(:email_recipient_info) { create(:user) }
  let(:email) {"lianna.newman@va.gov"}
  let(:name) {'Lianna'}
  let(:subject) { "Membership request submitted." }

  context "with recipient_info" do
    subject { MembershipMailer.membership_request_submitted(email_recipient_info: email_recipient_info) }

    describe "membership_request_submitted" do
      it "has the correct from" do
        expect(subject.from).to include("BoardofVeteransAppealsHearings@messages.va.gov")
      end

      it "has the correct subject line" do
        expect(subject).to eq(subject)
      end

      # it "sends an email" do
      #   expect(subject.deliver_now!).to change {
      #     ActionMailer::Base.deliveries.count }.by 1
      # end
    end

    subject { MembershipMailer.update_membership_request_status(email_recipient_info: email_recipient_info) }

    describe "update_membership_request_status" do
      let(:subject) { "Membership request status had been updated" }

      it "has the correct from" do
        expect(subject.from).to include("BoardofVeteransAppealsHearings@messages.va.gov")
      end

      it "has the correct subject line" do
        expect(subject).to eq(subject)
      end

      # it "sends an email" do
      #   expect(subject.deliver_now!).to change {
      #     ActionMailer::Base.deliveries.count }.by 1
      # end
    end

    subject { MembershipMailer.membership_request_submission(email_recipient_info: email_recipient_info) }

    describe "membership_request_submission" do
      let(:subject) { "New Membership Request Submission" }

      it "has the correct from" do
        expect(subject.from).to include("BoardofVeteransAppealsHearings@messages.va.gov")
      end

      it "has the correct subject line" do
        expect(subject).to eq(subject)
      end

         # it "sends an email" do
      #   expect(subject.deliver_now!).to change {
      #     ActionMailer::Base.deliveries.count }.by 1
      # end
    end
  end


  shared_context "membership_request_submitted" do
    subject { MembershipMailer.membership_request_submitted(email_recipient_info: email_recipient_info, custom_subject: custom_subject) }
  end

  shared_context "updated_membership_request_status" do
    subject { MembershipMailer.updated_membership_request_status(email_recipient_info: email_recipient_info, custom_subject: custom_subject) }
  end

  shared_context "membership_requested_submission" do
    subject do
      MembershipMailer.membership_requested_submission(email_recipient_info: recipient_info, custom_subject: custom_subject)
    end
  end
end

