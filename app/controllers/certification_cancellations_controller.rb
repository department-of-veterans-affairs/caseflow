class CertificationCancellationsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def create
    @certification_cancellation = CertificationCancellation.new(certification_cancellation_params)

    # Response to JSON format was introduced for CancelCertificationModal react component
    # Old cancellation modal is using HTML format
    respond_to do |format|
      if @certification_cancellation.save
        format.json { render json: { is_cancelled: true }, status: 201 }
      else
        format.json { render json: { is_cancelled: false }, status: 422 }
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
