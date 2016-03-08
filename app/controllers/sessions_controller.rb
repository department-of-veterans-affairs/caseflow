class SessionsController < ApplicationController
  def new
    return redirect_to(ssoi_url) unless current_user.ssoi_authenticated?

    push_ga_event(eventCategory: "VACOLS Login", eventAction: "Failed") if flash[:error]
  end

  def create
    unless current_user.authenticate(authentication_params)
      flash[:error] = "The username and password you entered don't match, please try again."
      return redirect_to login_path
    end

    redirect_to current_user.return_to || root_path
  end

  def destroy
    current_user.unauthenticate
    redirect_to login_path
  end

  protect_from_forgery with: :exception, except: %w(ssoi_saml_callback)

  def ssoi_saml_callback
    # https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
    auth_hash = request.env["omniauth.auth"] || {}

    if current_user.authenticate_ssoi(auth_hash)
      redirect_to current_user.return_to || login_path
    else
      ssoi_saml_failure("Failed to authenticate")
    end
  end

  def ssoi_saml_failure(failure_message = params[:message])
    render layout: "application", text: "<p>#{failure_message}</p>", status: 400
  end

  private

  def authentication_params
    { regional_office: params["regional_office"], password: params["password"] }
  end

  def ssoi_url
    User.ssoi_authentication_url
  end
end
