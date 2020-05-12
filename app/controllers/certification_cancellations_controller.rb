# frozen_string_literal: true

class CertificationCancellationsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def set_application
    RequestStore.store[:application] = "certifications"
  end

  def create
    @certification_cancellation = CertificationCancellation.new(certification_cancellation_params)

    if @certification_cancellation.save
      render json: { is_cancelled: true }, status: :created
    else
      render json: { is_cancelled: false }, status: :unprocessable_entity
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
