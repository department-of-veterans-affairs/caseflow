# frozen_string_literal: true

describe Memberships::SendMembershipRequestMailerJob do
  let(:recipient_info) { { email: email } }
  let(:email) { "bob.schmidt@va.gov" }

  subject { described_class.perform_now(type, recipient_info) }

  describe "#perform" do
    context "the type is SendMembershipRequestSubmittedEmail" do
      let(:type) { "SendMembershipRequestSubmittedEmail" }
      it "sends an email confirming membership request submitted successfully" do
        expect { subject }.to change {
          ActionMailer::Base.deliveries.count
        }.by 1
      end
    end

    context "the type is SendAdminsMembershipRequestSubmissionEmail" do
      let(:type) { "SendAdminsMembershipRequestSubmissionEmail" }
      it "sends an email to admins" do
        expect { subject }.to change {
          ActionMailer::Base.deliveries.count
        }.by 1
      end
    end

    context "the type is SendUpdatedMembershipRequestStatusEmail" do
      let(:type) { "SendUpdatedMembershipRequestStatusEmail" }
      it "sends a status update email to requestor" do
        expect { subject }.to change {
          ActionMailer::Base.deliveries.count
        }.by 1
      end
    end

    context "no type provided" do
      let(:type) { nil }

      it "throws an error" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(ArgumentError)
        end
      end
    end
  end
end
