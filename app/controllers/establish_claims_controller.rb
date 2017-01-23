class EstablishClaimsController < TasksController
  before_action :verify_assigned_to_current_user, only: [:show, :pdf, :cancel, :perform]
  before_action :verify_not_complete, only: [:perform]

  def perform
    Dispatch.new(claim: establish_claim_params, task: task).establish_claim!
    render json: {}
  end

  def assign_existing_end_product
    task.assign_existing_end_product!(params[:end_product_id])
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
    params.require(:claim).permit(:modifier, :poa, :end_product_code, :end_product_label,
                                  :end_product_modifier, :poa_code, :gulf_war_registry,
                                  :allow_poa, :suppress_acknowledgement_letter,
                                  :station_of_jurisdiction, :date)
  end

  def save_special_issues
    Appeal.update_attributes!(special_issues, params[:selected_issues])
  end
end
