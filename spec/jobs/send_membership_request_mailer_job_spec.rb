# frozen_string_literal: true

describe Memberships::SendMembershipRequestMailerJob do
  let(:type) { { email_type: email_type } }
  let(:recipient_info) { { email: email } }
  let(:email_type) { " " }
  let(:email) { "bob.schmidt@va.gov" }
  let(:name) { "Bob" }

  let(:perform_job) do
    SendMembershipRequestMailerJob.new(type: type, recipient_info: recipient_info)
  end

  describe "#perform" do
    context "the type is SendMembershipRequestSubmittedEmail" do
      type = "SendMembershipRequestSubmittedEmail"
      it "sends an email confirming membership request submitted successfully" do
        expect { perform_job.perform(type, recipient_info) }.to change {
          ActionMailer::Base.deliveries.count
        }.by 1
      end
    end

    context "the type is SendAdminsMembershipRequestSubmissionEmail" do
      type = "SendAdminsMembershipRequestSubmissionEmail"
      it "sends an email to admins" do
        expect { perform_job.perform(type, recipient_info) }.to change {
          ActionMailer::Base.deliveries.count
        }.by 1
      end
    end

    context "SendUpdatedMembershipRequestStatusEmail" do
      type = "SendUpdatedMembershipRequestStatusEmail"
      it "sends a status update email to requestor" do
        expect { perform_job.perform(type, recipient_info) }.to change {
          ActionMailer::Base.deliveries.count
        }.by 1
      end
    end

    context "no type provided" do
      let(:perform_job) do
        SendMembershipRequestMailerJob.new(type: nil, recipient_info: recipient_info)
      end

      subject do
        perform_job.perform(:recipient_info)
      end

      it "throws an error" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(ArgumentError)
        end
      end
    end
  end
end
