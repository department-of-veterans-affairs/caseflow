# frozen_string_literal: true

class MembershipRequestsController < ApplicationController
  def create
    # stuff
    puts "inside the create method."
    puts params.inspect
    puts safe_params.inspect
    puts current_user.inspect
    request_reason = safe_params[:requestReason]
    vha_access = safe_params[:vhaAccess]
    program_office_access = safe_params[:programOfficesAccess]
    # TODO: merge vhaccess into program offices access and require at least one of them to be set on the server side.
    puts "Requesting VHA: #{vha_access}"
    puts "Program Office access: #{program_office_access}"
    puts "Request reason: #{request_reason}"
    # respond

    # Build a mapping of options to the respective orgs
    # new_request = MembershipRequest.new(organization: VhaCamo.singleton, requestor: current_user)

    if true
      # TODO: created a mapping of the successful requests back to the message.
      # Example: Vha -> VHA group
      # Might do it client side instead? but probably do it here and build the message.
      render json: { data: { message: "success" } }, status: :created
    else
      render json: { data: { message: "errors" } }, status: :unprocessable_entity
    end
  end

  private

  def safe_params
    params.permit(:requestReason, :vhaAccess, programOfficesAccess: {})
  end
end
