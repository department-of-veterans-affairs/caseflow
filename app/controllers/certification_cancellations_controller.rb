class CertificationCancellationsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def create
    @certification_cancellation = CertificationCancellation.create(certification_cancellation_params)
    redirect_to @certification_cancellation
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
