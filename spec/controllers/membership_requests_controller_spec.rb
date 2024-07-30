# frozen_string_literal: true

describe MembershipRequestsController, :postgres, type: :controller do
  include ActiveJob::TestHelper

  let(:requestor) { create(:user, css_id: "REQUESTOR1", email: "requestoremail@test.com", full_name: "Gaius Baelsar") }
  let(:camo_admin) { create(:user, css_id: "CAMO ADMIN", email: "camoemail@test.com", full_name: "CAMO ADMIN") }
  let(:camo_org) { VhaCamo.singleton }
  let(:vha_business_line) { BusinessLine.find_by(url: "vha") }
  let(:existing_org) { create(:organization, name: "Testing Adverse Affects", url: "adverse-1") }
  let(:camo_membership_request) { create(:membership_request, organization: camo_org, requestor: requestor) }
  let(:vha_membership_request) { create(:membership_request, organization: vha_business_line, requestor: requestor) }

  before do
    User.authenticate!
    User.stub = user
    create_vha_orgs
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    OrganizationsUser.make_user_admin(camo_admin, camo_org)
    OrganizationsUser.make_user_admin(camo_admin, vha_business_line)
    existing_org.add_user(requestor)
  end

  describe "POST membership_requests/create/" do
    let(:user) { create(:user, full_name: "Billy Bob", email: "test@test.com", css_id: "BILLYBO") }

    context "with VHA request parameters" do
      let(:valid_params) do
        {
          organizationGroup: "VHA",
          membershipRequests: { "vhaAccess" => true },
          requestReason: "High Priority request"
        }
      end

      it "creates a new membership request for the user to the VHA org and queues email jobs" do
        expect do
          post :create, params: valid_params
        end.to change(MembershipRequest, :count).by(1)

        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

        expect(jobs).to be_an(Array)
        expect(jobs.length).to eq(2)
        expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
      end
    end

    context "with requests parameters to all VHA orgs" do
      let(:membership_requests) do
        {
          "vhaAccess" => true,
          "vhaCAMO" => true,
          "vhaCaregiverSupportProgram" => true,
          "veteranAndFamilyMembersProgram" => true,
          "paymentOperationsManagement" => true,
          "memberServicesHealthEligibilityCenter" => true,
          "memberServicesBeneficiaryTravel" => true,
          "prosthetics" => true
        }
      end

      let(:valid_params) do
        {
          organizationGroup: "VHA",
          membershipRequests: membership_requests,
          requestReason: "High Priority request"
        }
      end

      it "creates a new membership request for each vha organization and queues email jobs" do
        expect do
          post :create, params: valid_params
        end.to change(MembershipRequest, :count).by(8)

        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

        expect(jobs).to be_an(Array)
        expect(jobs.length).to eq(10)
        expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
      end
    end
  end

  describe "POST membership_requests/update/" do
    let(:user) { camo_admin }

    context "with the request action approved parameter and a predocket membership request id" do
      let(:valid_params) do
        {
          requestAction: "approved",
          id: camo_membership_request.id
        }
      end

      it "updates a predocket membership request to the approved status, updates"\
        " the decided_at time and decisioner_id, queues an email job, and adds the user to the VHA businessline"\
        " if they aren't already a member" do
        org_array = [camo_org, vha_business_line, existing_org]
        expect(requestor.organizations).to eq([existing_org])
        expect(camo_membership_request.status).to eq("assigned")
        post :update, params: valid_params
        # Reload the request and check the attributes
        camo_membership_request.reload
        expect(camo_membership_request.status).to eq("approved")
        expect(camo_membership_request.decider).to eq(camo_admin)
        expect(camo_membership_request.decided_at).to_not eq(nil)

        # Reload the requestor and check the organizations
        requestor.reload
        expect(requestor.organizations).to include(*org_array)

        # Check for the email job
        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }
        expect(jobs.first[:args]).to include("VhaPredocketApproved")
        expect(jobs).to be_an(Array)
        expect(jobs.length).to eq(1)
        expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
      end
    end

    context "with the request action approved parameter and a VHA membership request id" do
      let(:valid_params) do
        {
          requestAction: "approved",
          id: vha_membership_request.id
        }
      end

      it "updates a vha membership request to the approved status, updates"\
        " the decided_at time and decisioner_id, queues an email job, and adds the user to the VHA businessline" do
        org_array = [vha_business_line, existing_org]
        expect(requestor.organizations).to eq([existing_org])
        expect(vha_membership_request.status).to eq("assigned")
        post :update, params: valid_params
        # Reload the request and check the attributes
        vha_membership_request.reload
        expect(vha_membership_request.status).to eq("approved")
        expect(vha_membership_request.decider).to eq(camo_admin)
        expect(vha_membership_request.decided_at).to_not eq(nil)

        # Reload the requestor and check the organizations
        requestor.reload
        expect(requestor.organizations).to include(*org_array)

        # Check for the email job
        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }
        expect(jobs.first[:args]).to include("VhaBusinessLineApproved")
        expect(jobs).to be_an(Array)
        expect(jobs.length).to eq(1)
        expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
      end
    end

    context "with the request action denied parameter and a predocket membership request id" do
      let(:valid_params) do
        {
          requestAction: "denied",
          id: camo_membership_request.id
        }
      end

      it "updates a predocket membership request to the denied, updates the decided_at time "\
        "and decisioner_id, and queues an email job" do
        org_array = [existing_org]
        expect(requestor.organizations).to eq([existing_org])
        expect(camo_membership_request.status).to eq("assigned")
        post :update, params: valid_params
        # Reload the request and check the attributes
        camo_membership_request.reload
        expect(camo_membership_request.status).to eq("denied")
        expect(camo_membership_request.decider).to eq(camo_admin)
        expect(camo_membership_request.decided_at).to_not eq(nil)

        # Reload the requestor and check the organizations
        requestor.reload
        expect(requestor.organizations).to include(*org_array)

        # Check for the email job
        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }
        expect(jobs.first[:args]).to include("VhaPredocketDenied")
        expect(jobs).to be_an(Array)
        expect(jobs.length).to eq(1)
        expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
      end
    end

    context "with the request action denied parameter and a VHA membership request id" do
      let(:valid_params) do
        {
          requestAction: "denied",
          id: vha_membership_request.id
        }
      end

      it "updates a vha membership request to the denied status, updates the"\
        " decided_at time and decisioner_id, and queues an email job" do
        org_array = [existing_org]
        expect(requestor.organizations).to eq([existing_org])
        expect(vha_membership_request.status).to eq("assigned")
        post :update, params: valid_params
        # Reload the request and check the attributes
        vha_membership_request.reload
        expect(vha_membership_request.status).to eq("denied")
        expect(vha_membership_request.decider).to eq(camo_admin)
        expect(vha_membership_request.decided_at).to_not eq(nil)

        requestor.reload
        # Expect the requestor organizations to contain the camo_org and vha_business_line
        expect(requestor.organizations).to include(*org_array)

        # Check for the email job
        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }
        expect(jobs.first[:args]).to include("VhaBusinessLineDenied")
        expect(jobs).to be_an(Array)
        expect(jobs.length).to eq(1)
        expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
      end
    end
  end

  private

  def create_vha_orgs
    VhaCamo.singleton
    create(:business_line, name: "Veterans Health Administration", url: "vha")
    VhaCaregiverSupport.singleton
    create(:vha_program_office,
           name: "Community Care - Veteran and Family Members Program",
           url: "community-care-veteran-and-family-members-program")
    create(:vha_program_office,
           name: "Community Care - Payment Operations Management",
           url: "community-care-payment-operations-management")
    create(:vha_program_office,
           name: "Member Services - Health Eligibility Center",
           url: "member-services-health-eligibility-center")
    create(:vha_program_office, name: "Member Services - Beneficiary Travel", url: "member-services-beneficiary-travel")
    create(:vha_program_office, name: "Prosthetics", url: "prosthetics")
  end
end
