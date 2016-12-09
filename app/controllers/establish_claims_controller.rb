class EstablishClaimsController < TasksController
  before_action :verify_assigned_to_current_user, only: [:show, :new, :pdf, :cancel, :perform]
  before_action :verify_not_complete, only: [:new, :perform]

  def perform
    Dispatch.establish_claim!(claim: establish_claim_params, task: task)
    render json: {}
  end

  private

  def establish_claim_params
    params.require(:claim).permit(:modifier, :poa, :claim_label, :poa_code,
                                  :gulf_war, :allow_poa, :suppress_acknowledgement)
  end
end
