# frozen_string_literal: true

# :reek:InstanceVariableAssumption
class Api::V3::VbmsIntake::Ama::VeteransController < Api::V3::BaseController
  def show
    @veteran = Veteran.find_by(participant_id: params[:participant_id]).participant_id
    @page = ActiveRecord::Base.sanitize_sql(params[:page].to_i)
    render json: Api::V3::VbmsIntake::Ama::VbmsAmaDtoBuilder.new(@veteran, @page).json_response if @veteran
  end
end
