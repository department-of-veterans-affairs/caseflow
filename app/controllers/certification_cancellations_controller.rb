class CertificationCancellationsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def create
    CertificationCancellation.create(certification_cancellation_params)
    render "cancel"
  end

  private

  def certification_cancellation_params
    params.require(:certification_cancellation).permit(:certification_id, :cancellation_reason, :other_reason, :email)
  end

  def verify_access
    verify_authorized_roles("Certify Appeal")
  end

  def logo_name
    "Certification"
  end
end
