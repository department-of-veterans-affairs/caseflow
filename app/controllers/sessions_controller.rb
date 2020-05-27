# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :verify_authentication
  skip_before_action :deny_vso_access

  def new
    # :nocov:
    if Rails.application.config.sso_service_disabled
      return render "errors/500", layout: "application", status: :service_unavailable
    end
    # :nocov:

    session["return_to"] = request.original_url

    return redirect_to(sso_url) unless current_user

    # In order to use Caseflow, we need to know what regional office (RO) the user is from.
    # CSS will give us the station office ID. Some station office IDs correspond to multiple
    # RO IDs. In this case, we present a list of ROs to the user and ask which one they are.
    # :nocov:
    unless current_user.ro_is_ambiguous_from_station_office?
      redirect_to(session["return_to"] || root_path)
      return
    end
    # :nocov:

    @regional_office_options = current_user.station_offices.map do |regional_office_code|
      {
        "regionalOfficeCode" => regional_office_code,
        "regionalOffice" => RegionalOffice::CITIES[regional_office_code]
      }
    end
    @redirect_to = session["return_to"] || root_path
  end

  def update
    regional_office = params["regional_office"]

    # :nocov:
    unless regional_office
      render json: { "error": "Required parameter 'regional_office' is missing." }, status: :bad_request
      return
    end
    # :nocov:
    # The presence of the regional_office field is used to mark a user as logged in.
    session[:regional_office] = current_user.regional_office = regional_office.upcase
    current_user.update(selected_regional_office: regional_office.upcase)
    render json: {}
  end

  # :nocov:
  def destroy
    remove_user_from_session
    if session["global_admin"]
      add_user_to_session(session["global_admin"])
      session.delete("global_admin")
      redirect_to "/test/users"
    else
      redirect_to "/"
    end
  end

  def add_user_to_session(user_id)
    user = User.find(user_id)
    session["user"] = user.to_session_hash
    session[:regional_office] = user.users_regional_office
    RequestStore[:current_user] = user
  end
  # :nocov:

  private

  def remove_user_from_session
    session.delete(:regional_office)
    session.delete("user")
  end

  def sso_url
    ENV.fetch("SSO_URL", "/help")
  end
end
