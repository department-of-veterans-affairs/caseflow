# frozen_string_literal: true

class UserInfoController < ApplicationController
  include BgsService

  before_action :deny_non_bva_admins, only: [:represented_organizations]

  def represented_organizations
    participant_id = bgs.get_participant_id_for_css_id_and_station_id(css_id, station_id)
    vsos_user_represents = bgs.fetch_poas_by_participant_id(participant_id)

    render json: { represented_organizations: vsos_user_represents }
  end

  private

  def css_id
    css_id = params[:css_id]

    unless css_id.is_a?(String) && !css_id.empty? && css_id.match(/[^a-zA-Z]/).nil?
      fail(
        Caseflow::Error::InvalidParameter,
        parameter: "css_id",
        message: "css_id must contain only 1 or more letters"
      )
    end

    css_id
  end

  def station_id
    station_id = params[:station_id]

    unless station_id.is_a?(String) && !station_id.empty? && station_id.match(/[^0-9]/).nil?
      fail(
        Caseflow::Error::InvalidParameter,
        parameter: "station_id",
        message: "station_id must contain only 1 or more numbers"
      )
    end

    station_id
  end
end
