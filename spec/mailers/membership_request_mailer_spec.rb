# frozen_string_literal: true

describe MembershipRequestMailer do
  let(:email_recipient_info) { { email: email } }
  let(:email) { "bob.schmidt@va.gov" }
  let(:requestor) { create(:user, email: email, full_name: "Mario Lebowski") }
  let(:camo_org) { VhaCamo.singleton }
  let(:caregiver_support_org) { VhaCaregiverSupport.singleton }
  let(:membership_requests) do
    [
      create(:membership_request, organization: camo_org, requestor: requestor),
      create(:membership_request, organization: caregiver_support, requestor: requestor)
    ]
  end

  context "with recipient_info" do
    describe "membership_request_submitted" do
      let(:mailer) { MembershipRequestMailer.with(recipient_info: email_recipient_info).membership_request_submitted }
      it "has the correct From email address" do
        expect(mailer.from).to include("BoardofVeteransAppealsHearings@messages.va.gov")
      end

      it "has the correct subject line" do
        expect(mailer.subject).to eq("Membership request submitted.")
      end
    end

    describe "updated_membership_request_status" do
      let(:mailer) do
        MembershipRequestMailer.with(recipient_info: email_recipient_info).updated_membership_request_status
      end

      it "has the correct From address" do
        expect(mailer.from).to include("BoardofVeteransAppealsHearings@messages.va.gov")
      end

      it "has the correct subject line" do
        expect(mailer.subject).to eq("Membership request status updated.")
      end
    end

    describe "membership_request_submission" do
      let(:mailer) { MembershipRequestMailer.with(recipient_info: email_recipient_info).membership_request_submission }
      it "has the correct From email address" do
        expect(mailer.from).to include("BoardofVeteransAppealsHearings@messages.va.gov")
      end

      it "has the correct subject line" do
        expect(mailer.subject).to eq("New membership request recieved.")
      end
    end

    context "user request sent" do
      let(:mailer) do
        MembershipRequestMailer.with(recipient_info: requestor,
                                     requests: membership_requests,
                                     subject: COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_REQUESTOR_SUBMITTED)
          .user_request_sent
      end

      it "has the correct from email address" do
        expect(mailer.from).to include(COPY::VHA_BENEFIT_EMAIL_ADDRESS)
      end

      it "has the correct to email address" do
        expect(mailer.to).to include(requestor.email)
      end

      it "has the correct subject line" do
        expect(mailer.subject).to eq(COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_REQUESTOR_SUBMITTED)
      end

      it "renders the correct body text" do
        # Verify that it inserts the user name and the requested org names into the email.
        expect(mailer.body.encoded).to match("Dear #{requestor.full_name},")
        expect(mailer.body.encoded).to match("VHA CAMO and VHA Caregiver Support Program")
      end
    end

    context "admin request made" do
      let(:mailer) do
        MembershipRequestMailer.with(recipient_info: requestor,
                                     organization_name: caregiver_support_org.name,
                                     to: COPY::VHA_CAREGIVER_SUPPORT_EMAIL_ADDRESS,
                                     subject: COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_VHA_ADMIN_REQUEST_RECEIVED)
          .admin_request_made
      end

      it "has the correct from email address" do
        expect(mailer.from).to include(COPY::VHA_BENEFIT_EMAIL_ADDRESS)
      end

      it "has the correct to email address" do
        expect(mailer.to).to include(COPY::VHA_CAREGIVER_SUPPORT_EMAIL_ADDRESS)
      end

      it "has the correct subject line" do
        expect(mailer.subject).to eq(COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_VHA_ADMIN_REQUEST_RECEIVED)
      end

      it "renders the correct body text" do
        expect(mailer.body.encoded).to match("Dear #{caregiver_support_org.name} admin,")
        expect(mailer.body.encoded).to match(
          "You have received a new request for access to #{caregiver_support_org.name}."
        )
      end
    end
  end
end
