class CertificationCancellationsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def create
    @certification_cancellation = CertificationCancellation.new(certification_cancellation_params)

    if @certification_cancellation.save
      render json: { is_cancelled: true }, status: 201
    else
      render json: { is_cancelled: false }, status: 422
    end
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
