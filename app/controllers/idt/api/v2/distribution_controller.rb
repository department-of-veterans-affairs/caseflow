class Idt::Api::V2::AppealsController < Idt::Api::V1::BaseController

  protect_from_forgery with: :exception
  before_action :verify_access

  skip_before_action :verify_authenticity_token, only: [:outcode]

  def get_distribution


  end

  def distribution_id()

    distribution = Distribution.find(params[:distribution_id])

  end



end
