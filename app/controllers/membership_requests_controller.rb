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
    # TODO: merge vhaccess into program offices access and require at least one of them to be set on the server side.
    # puts "Requesting VHA: #{vha_access}"
    puts "Program Office access: #{membership_requests_hash}"
    puts "Request reason: #{request_reason}"
    # respond

    # TODO: Build a mapping of options to the respective orgs
    # TODO: Probably merge the VHA request with this options hash to make processing easier?
    # test_hash =
    #   {
    #     "vhaCAMO" => true,
    #     "veteranAndFamilyMembersProgram" => true,
    #     "vhaCaregiverSupportProgram" => true,
    #     "paymentOperationsManagement" => true,
    #     "memberServicesHealthEligibilityCenter" => true,
    #     "memberServicesBeneficiaryTravel" => true,
    #     "prosthetics" => true
    #   }

    # TODO: Merge VHA access into this hash and rename it to make processing easier
    requested_org_access_list = build_vha_org_list(membership_requests_hash)
    # MembershipRequest.new(organization: VhaCamo.singleton, requestor: current_user, note: request_reason)

    # Now build a request object for each org and return an array of org_names to be used in the success message
    # TODO: Although this shouldn't be possible through the form make sure they can't submit two requests
    # To the same org if there is one pending
    org_names = requested_org_access_list.map do |org|
      org_name = org.name
      # Build a request object for each org
      # TODO: Turn this back on after testing the string
      # new_request = MembershipRequest.new(
      #   organization: org,
      #   requestor: current_user,
      #   note: request_reason
      # )
      # new_request.save
      org_name
    end
    # org_name_strings = build
    # org_name_strings = org_names_to_message_string_names(org_names)
    # org_name_strings = ["VHA CAMO", "Veterans and Family Members program office"]

    # Return the success message if the saves were successful
    # TODO: make this work with all of the saves somehow probably with a catch or an array of booleans
    # TODO: can also do a prevalidation or valid check on all of them?
    if true
    # if new_request.save
      # TODO: created a mapping of the successful requests back to the message.
      # Example: Vha -> VHA group
      # Might do it client side instead? but probably do it here and build the message.
      render json: { data: { message: build_success_message(org_names) } }, status: :created
    else
      render json: { data: { message: "errors" } }, status: :unprocessable_entity
    end
  end

  private

  def safe_params
    params.permit(:requestReason, membershipRequests: {})
  end

  def build_success_message(requested_org_names)
    # TODO: Probably need to do some more text mapping somehow. Also add program office to the strings?
    formatted_requested_org_names = org_names_to_message_string_names(requested_org_names)
    formatted_org_text = if formatted_requested_org_names.count == 1
                           "the #{formatted_requested_org_names.first}"
                         else
                           formatted_requested_org_names.to_sentence
                         end
    format(COPY::VHA_MEMBERSHIP_REQUEST_FORM_SUBMIT_SUCCESS_MESSAGE, formatted_org_text)
  end

  # TODO: should this be somewhere else?
  # TODO: pass in the comparison hash for mapping keys to orgs to make it generic
  def build_vha_org_list(org_options)
    # Maybe get only the keys with the value true? But that's probably impossible/unnecessary
    key_names = org_options.keys
    # TODO: Ask about formatting the strings. Add program office to most of them?
    keys_to_org_hash =
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
    # keys_to_org_hash.values_at(*keys.map(&:to_sym))
    org_names = keys_to_org_hash.values_at(*key_names)

    org_list = org_names.map do |org_name|
      # This is a bit gross
      Organization.find_by(name: org_name)
    end

    org_list
  end

  def org_names_to_message_string_names(org_names)
    # TODO: This is getting ridiculous. Please fix this somehow.
    # Maybe by using the vha help constants file in a lot of places
    org_name_to_string_hash = {
      "Veterans Health Administration" => "VHA group",
      "VHA CAMO" => "VHA CAMO",
      "VHA Caregiver Support Program" => "VHA Caregiver Support Program",
      "Community Care - Veteran and Family Members Program" => "Veteran and Family Members program office",
      "Community Care - Payment Operations Management" => "Payment Operations Management",
      "Member Services - Health Eligibility Center" => "Member Services - Health Eligibility Center",
      "Member Services - Beneficiary Travel" => "Member Services - Beneficiary Travel",
      "Prosthetics" => "Prosthetics"
    }
    org_name_to_string_hash.values_at(*org_names)
    # org_strings
  end
end
