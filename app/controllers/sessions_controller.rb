class SessionsController < ApplicationController
  def new
    return redirect_to(ssoi_url) unless current_user.ssoi_authenticated?
  end

  def create
    unless current_user.authenticate(authentication_params)
      flash[:error] = "Login ID and password did not work. Please try again."
      return redirect_to login_path
    end

    redirect_to current_user.return_to || root_path
  end

  def destroy
    current_user.unauthenticate
    redirect_to login_path
  end

  private

  def authentication_params
    { regional_office: params["regional_office"], password: params["password"] }
  end

  def ssoi_url
    User.ssoi_authentication_url
  end
end
