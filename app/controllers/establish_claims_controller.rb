class EstablishClaimsController < TasksController
  def create
    transaction do
      Dispatch.establish_claim!(establish_claim_params)
      task.complete!(0)
    end

    render json: {}
  end

  private
  def establish_claim_params
    params.require(:claim).permit(:modifier, :poa, :claim_label, :poa_code)
  end

end
