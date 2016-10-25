class SessionsController < ApplicationController
  def new
    if Rails.application.config.sso_service_disabled
      @error_title = "Login Service Unavailable"
      @error_subtitle = "The VA's common login service is currently down."
      @error_retry_external_service = "the system"
      return render "errors/500", layout: "application", status: 503
    end

    return redirect_to(ENV["SSO_URL"]) unless current_user
  end

  def create
    unless current_user.authenticate(authentication_params)
      flash[:error] = "The username and password you entered don't match, please try again."
      return redirect_to login_path
    end

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
