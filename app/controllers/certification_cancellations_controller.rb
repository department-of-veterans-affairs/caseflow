class CertificationCancellationsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def create
    @certification_cancellation = CertificationCancellation.new(certification_cancellation_params)

    respond_to do |format|
      if @certification_cancellation.save
        format.html { redirect_to @certification_cancellation }
        format.json { render json: { is_cancelled: true }.to_json }
      else
        format.html { redirect_to "errors/500", layout: "application", status: 500 }
        format.json { render json: { is_cancelled: false }.to_json }
      end
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
