# frozen_string_literal: true

class UserInfoController < ApplicationController
  include BGSServiceConcern

  before_action :deny_non_bva_admins, only: [:represented_organizations]

  def represented_organizations
    participant_id = bgs.get_participant_id_for_css_id_and_station_id(css_id, station_id)
    vsos_user_represents = bgs.fetch_poas_by_participant_id(participant_id)

    render json: { represented_organizations: vsos_user_represents }
  end

  private

  def css_id
    unless /^\w+$/.match?(params[:css_id])
      fail(
        Caseflow::Error::InvalidParameter,
        parameter: "css_id",
        message: "css_id must contain only 1 or more number and letter characters"
      )
    end

    params[:css_id]
  end

  def station_id
    unless /^[0-9]+$/.match?(params[:station_id])
      fail(
        Caseflow::Error::InvalidParameter,
        parameter: "station_id",
        message: "station_id must contain only 1 or more numbers"
      )
    end

    params[:station_id]
  end
end
