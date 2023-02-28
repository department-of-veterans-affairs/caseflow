# frozen_string_literal: true

describe MembershipRequestsController, :postgres, type: :controller do
  before do
    User.authenticate!
    User.stub = user
    create_vha_orgs
  end

  describe "POST membership_requests/create/" do
    let(:user) { create(:default_user) }
    context "with VHA request parameters" do
      let(:valid_params) do
        {
          organizationGroup: "VHA",
          membershipRequests: { "vhaAccess" => true },
          requestReason: "High Priority request"
        }
      end

      it "creates a new membership request for the user to the VHA org and sends emails" do
        expect do
          post :create, params: valid_params
        end.to change(MembershipRequest, :count).by(1)

        expect(ActionMailer::Base.deliveries.count).to eq(2)
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

      it "creates a new membership request for each vha organization and sends emails" do
        expect do
          post :create, params: valid_params
        end.to change(MembershipRequest, :count).by(8)

        expect(ActionMailer::Base.deliveries.count).to eq(10)
      end
    end
  end

  def create_vha_orgs
    create(:business_line, name: "Veterans Health Administration", url: "vha")
    VhaCamo.singleton
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
