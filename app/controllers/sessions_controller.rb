class SessionsController < ApplicationController
  skip_before_action :verify_authentication

  def new
    if Rails.application.config.sso_service_disabled
      @error_title = "Login Service Unavailable"
      @error_subtitle = "The VA's common login service is currently down."
      @error_retry_external_service = "the system"
      return render "errors/500", layout: "application", status: 503
    end

    return redirect_to(ENV["SSO_URL"]) unless current_user

    # In order to use Caseflow, we need to know what regional office (RO) the user is from.
    # CSS will give us the station office ID. Some station office IDs correspond to multiple
    # RO IDs. In this case, we present a list of ROs to the user and ask which one they are.
    unless current_user.ro_is_ambiguous_from_station_office?
      redirect_to(session["return_to"] || root_path)
      return
    end

    @regional_office_options = current_user.station_offices.map do |regional_office_code|
      {
        "regionalOfficeCode" => regional_office_code,
        "regionalOffice" => VACOLS::RegionalOffice::CITIES[regional_office_code]
      }
    end
    @redirect_to = session["return_to"] || root_path
  end

  def update
    regional_office = params["regional_office"]
    unless regional_office
      render json: { "error": "Required parameter 'regional_office' is missing." }, status: 400
      return
    end

    # The presence of the regional_office field is used to mark a user as logged in.
    session[:regional_office] = current_user.regional_office = regional_office.upcase
    render json: {}
  end

  def destroy
    session.delete(:regional_office)
    session.delete("user")
    redirect_to "/"
  end
end
