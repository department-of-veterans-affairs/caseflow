class Api::V3::VbmsIntake::VeteransController < Api::V3::BaseController
  def issues
    @veteran = Veteran.find(params[:id]).id
    @page = params[:page].to_i
    render json: Api::V3::VbmsIntake::VbmsAmaDtoBuilder.new(@veteran, @page).json_response if @veteran
  end
end
