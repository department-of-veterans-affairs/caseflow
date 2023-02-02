# frozen_string_literal: true

class MembershipRequestsController < ApplicationController
  before_action :verify_access

  def index
    respond_to do |format|
      # Do we need this line?
      format.html { render template: "queue/index" }
      # Might need to conditionally render this for some reason? Who can see this form and options?
      format.json do
        render json: current_user.can_view_membership_requests? ? membership_requests : []
      end
    end
  end

  private

  def membership_requests
    # This might work? but then they will all be grouped together into one block of requests for various orgs.
    # TODO: Maybe create a serializer for MembershipRequests?
    MembershipRequest.find_by(organization: current_user.administered_teams)
  end
end
