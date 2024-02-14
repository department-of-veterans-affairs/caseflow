# frozen_string_literal: true

class MembershipRequestsController < ApplicationController
  # To create Membership Request
  # e.g, for VHA Businessline request => POST /membership_requests,
  # {
  #   organizationGroup: "VHA",
  #   membershipRequests: { "vhaAccess" => true },
  #   requestReason: "High Priority request"
  # }
  def create
    allowed_params = safe_params
    membership_requests_hash = allowed_params[:membershipRequests]
    organization_group = allowed_params[:organizationGroup]

    requested_org_access_list = build_org_list(membership_requests_hash, org_name_mapping(organization_group))

    created_membership_requests = MembershipRequest.create_many_from_params_and_send_creation_emails(
      requested_org_access_list,
      allowed_params,
      current_user
    )

    # Serialize the Membership Requests and extract the attributes
    serialized_requests = MembershipRequestSerializer.new(created_membership_requests, is_collection: true)
      .serializable_hash[:data]
      .map { |hash| hash[:attributes] }

    render json: { data: { newMembershipRequests: serialized_requests } }, status: :created
  rescue ActiveRecord::RecordInvalid => error
    invalid_record_error(error.record)
  end

  # To update the status of a Membership Request
  # e.g, for VHA Businessline request => POST /membership_requests/#{membershipRequestId},
  # {
  #   organizationGroup: "VHA",
  #   id: 55,
  #   requestAction: "approved"
  # }
  def update
    no_cache

    membership_request = MembershipRequest.find(request_action_params[:id])
    membership_request.update_status_and_send_email(request_action_params[:requestAction], current_user)

    membership_request_hash = MembershipRequestSerializer.new(membership_request)
      .serializable_hash[:data][:attributes]

    json_user = ::WorkQueue::AdministeredUserSerializer.new(
      membership_request.requestor,
      params: { organization: membership_request.organization }
    ).serializable_hash[:data]

    json_hash = { membershipRequest: membership_request_hash, updatedUser: json_user }

    render json: json_hash, status: :ok
  rescue ActiveRecord::RecordInvalid => error
    invalid_record_error(error.record)
  end

  private

  def safe_params
    params.permit(:requestReason, :organizationGroup, membershipRequests: {})
  end

  def request_action_params
    params.permit(:id, :requestAction)
  end

  def build_org_list(org_options, keys_to_org_name_hash)
    # Get all of the keys from the options that have values that are truthy
    key_names = org_options.select { |_, value| value }.keys

    # Remove any bad nils from unmatched keys
    org_names = keys_to_org_name_hash.values_at(*key_names).compact

    org_list = org_names.map do |org_name|
      Organization.find_by(name: org_name)
    end

    org_list
  end

  # Generic mapping of options keys to the respective organization names
  # This method will need to be expanded as more organizations want to use this controller
  def org_name_mapping(org_group)
    org_hash = {
      VHA: vha_org_mapping
    }

    org_hash[org_group.to_sym]
  end

  # This is a mapping of option values to the organization names
  def vha_org_mapping
    {
      "vhaAccess" => "Veterans Health Administration",
      "vhaCAMO" => "VHA CAMO",
      "vhaCaregiverSupportProgram" => "VHA Caregiver Support Program",
      "veteranAndFamilyMembersProgram" => "Community Care - Veteran and Family Members Program",
      "paymentOperationsManagement" => "Community Care - Payment Operations Management",
      "memberServicesHealthEligibilityCenter" => "Member Services - Health Eligibility Center",
      "memberServicesBeneficiaryTravel" => "Member Services - Beneficiary Travel",
      "prosthetics" => "Prosthetics"
    }
  end
end
