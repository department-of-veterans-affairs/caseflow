# frozen_string_literal: true

describe Memberships::SendMembershipRequestMailerJob do
  let(:type) { { email_type: email_type } }
  let(:recipient_info) { { email: email } }
  let(:email_type) { " " }
  let(:email) { "bob.schmidt@va.gov" }
  let(:name) { "Bob" }

  let(:perform_job) do
    Memberships::SendMembershipRequestMailerJob.new(type, recipient_info)
  end

  describe "#perform" do
    context "the type is SendMembershipRequestSubmittedEmail" do
      let(:type) { "SendMembershipRequestSubmittedEmail" }
      it "sends an email confirming membership request submitted successfully" do
        expect { perform_job.perform(type, recipient_info) }.to change {
          ActionMailer::Base.deliveries.count
        }.by 1
      end
    end

    context "the type is SendAdminsMembershipRequestSubmissionEmail" do
      let(:type) { "SendAdminsMembershipRequestSubmissionEmail" }
      it "sends an email to admins" do
        expect { perform_job.perform(type, recipient_info) }.to change {
          ActionMailer::Base.deliveries.count
        }.by 1
      end
    end

    context "SendUpdatedMembershipRequestStatusEmail" do
      let(:type) { "SendUpdatedMembershipRequestStatusEmail" }
      it "sends a status update email to requestor" do
        expect { perform_job.perform(type, recipient_info) }.to change {
          ActionMailer::Base.deliveries.count
        }.by 1
      end
    end

    context "no type provided" do
      let(:type) { nil }
      
      subject { perform_job.perform }

      it "throws an error" do
        is_expected.to raise_error do |error|
          expect(error).to be_a(ArgumentError)
        end
      end
    end
    end
  end
end
