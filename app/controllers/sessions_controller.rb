class SessionsController < ApplicationController
  def new
    return redirect_to(ssoi_url) unless current_user.ssoi_authenticated?
  end

  def create
    if current_user.authenticate(authentication_params)
      redirect_to current_user.return_to || root_path
    end
  end

  def destroy
    current_user.unauthenticate
    redirect_to login_path
  end

  protect_from_forgery with: :exception, except: %w(ssoi_saml_callback)

  def ssoi_saml_callback
    # https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
    auth_hash = request.env["omniauth.auth"]

    if current_user.authenticate_ssoi(auth_hash)
      redirect_to current_user.return_to
    else
      ssoi_saml_failure(message: "Failed to authenticate")
    end
  end

  def ssoi_saml_failure(message = params[:message])
    # TODO: render message in a page
    render text: "failure #{message}"
  end

  private

  def authentication_params
    { regional_office: params["regional_office"], password: params["password"] }
  end

  def ssoi_url
    User.ssoi_authentication_url
  end
end
