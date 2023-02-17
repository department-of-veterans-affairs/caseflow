# frozen_string_literal: true

class MembershipRequestsController < ApplicationController
  # TODO: This needs to be generalized. I need to pass another param down to decide which create method to use
  # Create itself should not be specific to VHA
  def create
    # stuff
    puts "inside the create method."
    # puts params.inspect
    # puts safe_params.inspect
    puts current_user.inspect
    allowed_params = safe_params
    request_reason = allowed_params[:requestReason]
    # vha_access = allowed_params[:vhaAccess]
    # requested_program_office_access_hash = allowed_params[:programOfficesAccess]
    membership_requests_hash = allowed_params[:membershipRequests]
    organization_group = allowed_params[:organizationGroup]
    # TODO: merge vhaccess into program offices access and require at least one of them to be set on the server side.
    # puts "Requesting VHA: #{vha_access}"
    puts "Program Office access: #{membership_requests_hash}"
    puts "Request reason: #{request_reason}"
    puts "Requesting Organization Group: #{organization_group}"
    # respond

    requested_org_access_list = build_org_list(membership_requests_hash, org_name_mapping(organization_group))
    # MembershipRequest.new(organization: VhaCamo.singleton, requestor: current_user, note: request_reason)

    # Now build a request object for each org and return an array of org_names to be used in the success message
    # TODO: Although this shouldn't be possible through the form make sure they can't submit two requests
    # To the same org if there is one pending
    # errors = []
    # created_membership_requests = []
    # org_names = requested_org_access_list.map do |org|
    #   org_name = org.name
    #   # Build a request object for each org
    #   # TODO: Turn this back on after testing the string
    #   # TODO: Probably push this logic down to the model class.
    #   # TODO: Decide if the controller or model class should be the one to send an email or not
    #   new_request = MembershipRequest.new(
    #     organization: org,
    #     requestor: current_user,
    #     note: request_reason
    #   )

    #   if new_request.save
    #     created_membership_requests << new_request
    #   else
    #     errors << new_request.errors.full_messages
    #   end

    #   org_name
    # end

    created_membership_requests = MembershipRequest.create_many_from_params_and_send_creation_emails(
      requested_org_access_list,
      safe_params,
      current_user
    )

    # TODO: This needs to be the serialized membership requests that were saved successfully instead of this hash
    # test_hash = org_names.map { |org_name| { name: org_name } }

    # Serialize the Membership Requests and extract the attributes
    serialized_requests = MembershipRequestSerializer.new(created_membership_requests, is_collection: true)
      .serializable_hash[:data]
      .map { |hash| hash[:attributes] }

    # if errors.empty?
    #   # TODO: created a mapping of the successful requests back to the message.
    #   # Example: Vha -> VHA group
    #   # Might do it client side instead? but probably do it here and build the message.
    #   # It's easier to jest test if I do it client side.
    #   render json: { data: { newMembershipRequests: serialized_requests, message: build_success_message(org_names) } },
    #          status: :created
    # else
    #   render json: { data: { message: errors.flatten } }, status: :unprocessable_entity
    # end

    render json: { data: { newMembershipRequests: serialized_requests } }, status: :created
  end

  private

  def safe_params
    params.permit(:requestReason, :organizationGroup, membershipRequests: {})
  end

  # TODO: should this be somewhere else?
  def build_org_list(org_options, keys_to_org_name_hash)
    # Get all of the keys from the options that have values that are truthy
    key_names = org_options.select { |_, value| value }.keys

    # Remove any bad nils from unmatched keys
    # org_names = keys_to_org_hash.values_at(*key_names).compact
    org_names = keys_to_org_name_hash.values_at(*key_names).compact

    org_list = org_names.map do |org_name|
      # This is a bit gross
      Organization.find_by(name: org_name)
    end

    org_list
  end

  # Generic mapping of options keys to the respective organization names
  # This method will need to be expanded as more organizations want to use this controller
  def org_name_mapping(org_group)
    org_hash = case org_group
               when "VHA"
                 vha_org_mapping
               else
                 {}
               end
    org_hash
  end

  # This is a mapping of option values to the organization names
  # Could also just pass down the Names from the client to avoid this.
  # TODO: Probably should just send names everywhere
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
