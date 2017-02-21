class Admin::EstablishClaimsController < ApplicationController
  before_action :verify_system_admin

  def show
    @create_establish_claim = CreateEstablishClaim.new
    @existing_tasks = EstablishClaim.newest_first.limit(100)
  end

  def create
    @create_establish_claim = CreateEstablishClaim.new(create_establish_claim_params)

    if @create_establish_claim.perform!
      flash[:success] = "Task created or already existed"
    else
      flash[:error] = @create_establish_claim.error_message
    end

    redirect_to admin_establish_claim_path
  end

  def create_establish_claim_params
    params.require(:create_establish_claim).permit(:vbms_id, :decision_type)
  end
end
