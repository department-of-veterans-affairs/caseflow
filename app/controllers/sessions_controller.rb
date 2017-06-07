class SessionsController < ApplicationController
  skip_before_action :verify_authentication

  def new
    if Rails.application.config.sso_service_disabled
      @error_title = "Login Service Unavailable"
      @error_subtitle = "The VA's common login service is currently down."
      @error_retry_external_service = "the system"
      return render "errors/500", layout: "application", status: 503
    end

    if current_user.ro_is_ambiguous_from_station_office?
      @regional_office_options = current_user.station_offices.map do |regional_office_code|
        {
          "regional_office_code" => regional_office_code,  
          "city" => VACOLS::RegionalOffice::CITIES[regional_office_code]
        }
      end
    else
      return redirect_to(ENV["SSO_URL"]) unless current_user
    end
  end

  def create
    unless current_user.authenticate(authentication_params)
      flash[:error] = "The username and password you entered don't match. Please try again."
      return redirect_to login_path
    end

    # The presence of the regional_office field is used to mark a user as logged in.
    session[:regional_office] = current_user.regional_office
    redirect_to session["return_to"] || root_path
  end

  def destroy
    session.delete(:regional_office)
    session.delete("user")
    redirect_to "/"
  end

  private

  def authentication_params
    { regional_office: params["regional_office"], password: params["password"] }
  end
end
