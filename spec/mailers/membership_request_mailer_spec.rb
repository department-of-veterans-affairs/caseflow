# frozen_string_literal: true

describe MembershipRequestMailer do
  let(:email_recipient_info) { { email: email } }
  let(:email) { "bob.schmidt@va.gov" }
  let(:requestor) { create(:user, email: email, full_name: "Mario Lebowski") }
  let(:camo_org) { VhaCamo.singleton }
  # TODO: This might not work since they aren't VHA orgs?
  let(:user_orgs) do
    [
      create(:organization, name: "New Org 1", url: "new-org-1"),
      create(:organization, name: "New Org 2", url: "new-org-2")
    ]
  end
  let(:caregiver_support_org) { VhaCaregiverSupport.singleton }
  let(:membership_requests) do
    [
      create(:membership_request, organization: camo_org, requestor: requestor),
      create(:membership_request, organization: caregiver_support_org, requestor: requestor)
    ]
  end

  before do
    user_orgs.each do |org|
      org.add_user(requestor)
      org.save
    end
  end

  context "user request sent" do
    let(:mailer) do
      MembershipRequestMailer.with(recipient_info: requestor,
                                   requests: membership_requests,
                                   subject: COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_REQUESTOR_SUBMITTED)
        .user_request_created
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

  context "vha_business_line_approved" do
    let(:mailer) do
      MembershipRequestMailer.with(requestor: requestor,
                                   accessible_groups: requestor.organizations.map(&:name))
        .vha_business_line_approved
    end

    it "has the correct from email address" do
      expect(mailer.from).to include(COPY::VHA_BENEFIT_EMAIL_ADDRESS)
    end

    it "has the correct to email address" do
      expect(mailer.to).to include(requestor.email)
    end

    it "has the correct subject line" do
      expect(mailer.subject).to eq(COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_REQUESTOR_APPROVED)
    end

    it "renders the correct body text" do
      expect(mailer.body.encoded).to match("Dear #{requestor.full_name},")
      expect(mailer.body.encoded).to match(
        "We approved your request for access to VHA pages within Caseflow."
      )
      expect(mailer.body.encoded).to have_selector("p", text: "New Org 1")
      expect(mailer.body.encoded).to have_selector("p", text: "New Org 2")
      expect(mailer.body.encoded).to have_selector("div", text: "Veterans Health Administration")
    end
  end

  context "vha_business_line_denied" do
    let(:mailer) do
      MembershipRequestMailer.with(requestor: requestor,
                                   accessible_groups: requestor.organizations.map(&:name))
        .vha_business_line_denied
    end

    it "has the correct from email address" do
      expect(mailer.from).to include(COPY::VHA_BENEFIT_EMAIL_ADDRESS)
    end

    it "has the correct to email address" do
      expect(mailer.to).to include(requestor.email)
    end

    it "has the correct subject line" do
      expect(mailer.subject).to eq(COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_REQUESTOR_DENIED)
    end

    it "renders the correct body text" do
      expect(mailer.body.encoded).to match("Dear #{requestor.full_name},")
      expect(mailer.body.encoded).to match(
        "At this time, we have denied your request for access to general VHA pages in Caseflow. "\
          "Your existing group memberships did not change."
      )
      expect(mailer.body.encoded).to have_selector("p", text: "New Org 1")
      expect(mailer.body.encoded).to have_selector("p", text: "New Org 2")
      expect(mailer.body.encoded).to have_selector("div", text: "Veterans Health Administration")
    end
  end

  context "vha predocket organization approved" do
    let(:pending_org_request_names) { ["VHA Caregiver Support Program", "Prosthetics"] }
    let(:mailer_parameters) do
      {
        requestor: requestor,
        accessible_groups: requestor.organizations.map(&:name),
        organization_name: camo_org.name,
        pending_organization_request_names: pending_org_request_names
      }
    end
    let(:mailer) do
      MembershipRequestMailer.with(mailer_parameters)
        .vha_predocket_organization_approved
    end

    it "has the correct from email address" do
      expect(mailer.from).to include(COPY::VHA_BENEFIT_EMAIL_ADDRESS)
    end

    it "has the correct to email address" do
      expect(mailer.to).to include(requestor.email)
    end

    it "has the correct subject line" do
      expect(mailer.subject).to eq(COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_REQUESTOR_APPROVED)
    end

    it "renders the correct body text" do
      expect(mailer.body.encoded).to match("Dear #{requestor.full_name},")
      expect(mailer.body.encoded).to match(
        "We approved your request for Caseflow #{camo_org.name} pages,"\
        " which also includes access to the VHA pages."
      )
      # Additional Org access list
      expect(mailer.body.encoded).to have_selector("p", text: "New Org 1")
      expect(mailer.body.encoded).to have_selector("p", text: "New Org 2")

      # Pending requests list
      expect(mailer.body.encoded).to match(
        "You still have pending requests for other Pre-docket offices. You'll get a separate decision email"\
        " from each Pre-docket office listed below."
      )
      expect(mailer.body.encoded).to have_selector("p", text: "VHA Caregiver Support Program")
      expect(mailer.body.encoded).to have_selector("p", text: "Prosthetics")

      # Signature line
      expect(mailer.body.encoded).to have_selector("div", text: "Veterans Health Administration")
    end

    context "with no pending requests" do
      let(:pending_org_request_names) { nil }
      it "renders the correct body text" do
        expect(mailer.body.encoded).to match("Dear #{requestor.full_name},")
        expect(mailer.body.encoded).to match(
          "We approved your request for Caseflow #{camo_org.name} pages,"\
          " which also includes access to the VHA pages."
        )
        # Additional Org access list
        expect(mailer.body.encoded).to have_selector("p", text: "New Org 1")
        expect(mailer.body.encoded).to have_selector("p", text: "New Org 2")
        expect(mailer.body.encoded).to_not match(
          "You still have pending requests for other Pre-docket offices. You'll get a separate decision email"\
          " from each Pre-docket office listed below."
        )
      end
    end
  end
end
