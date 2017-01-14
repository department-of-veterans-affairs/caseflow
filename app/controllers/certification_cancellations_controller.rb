class CertificationCancellationsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def create
    render "cancel"
  end

  private

  def verify_access
    verify_authorized_roles("Certify Appeal")
  end
end
