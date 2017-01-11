class EstablishClaimsController < TasksController
  before_action :verify_assigned_to_current_user, only: [:show, :pdf, :cancel, :perform]
  before_action :verify_not_complete, only: [:perform]

  def perform
    Dispatch.establish_claim!(claim: establish_claim_params, task: task)
    render json: {}
  end

  def select_ep
    task.assign_existing_ep!(params[:end_product_id])
    render json: {}
  end

  def start_text
    "Establish Next Claim"
  end

  def logo_name
    "Dispatch"
  end

  def logo_path
    establish_claims_path
  end

  private

  def establish_claim_params
    params.require(:claim).permit(:modifier, :poa, :claim_label, :poa_code,
                                  :gulf_war, :allow_poa, :suppress_acknowledgement)
  end
end
