class EstablishClaimsController < TasksController
  before_action :verify_assigned_to_current_user, only: [:review, :perform]
  before_action :verify_not_complete, only: [:review, :perform]

  def perform
    Dispatch.establish_claim!(claim: establish_claim_params, task: task)
    render json: {}
  end

  def review
    # Future safeguard for when we give managers a show view
    # for a given task
    task.start! if current_user == task.user
    render "review"
  end

  private

  def establish_claim_params
    params.require(:claim).permit(:modifier, :poa, :claim_label, :poa_code,
                                  :gulf_war, :allow_poa, :suppress_acknowledgement)
  end
end
