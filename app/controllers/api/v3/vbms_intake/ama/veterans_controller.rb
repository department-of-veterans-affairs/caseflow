# frozen_string_literal: true

# :reek:InstanceVariableAssumption
class Api::V3::VbmsIntake::Ama::VeteransController < Api::V3::BaseController
  include ApiV3FeatureToggleConcern

  before_action do
    FeatureToggle.enabled?(:api_v3_vbms_intake_ama)
  end

  def show
    @veteran = Veteran.find_by!(participant_id: params[:participant_id])
    @page = ActiveRecord::Base.sanitize_sql(params[:page].to_i) if params[:page]
    # Disallow page(0) since page(0) == page(1) in kaminari. This is to avoid confusion.
    (@page == 0) ? @page = 1 : @page ||= 1
    render json: Api::V3::VbmsIntake::Ama::VbmsAmaDtoBuilder.new(@veteran, @page).json_response if @veteran
  end
end
