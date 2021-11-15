# frozen_string_literal: true

class Idt::Api::V1::UploadVbmsDocumentController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :verify_access

  rescue_from StandardError do |e|
    Raven.capture_exception(e)
    if e.class.method_defined?(:serialize_response)
      render(e.serialize_response)
    else
      render json: { message: "Unexpected error: #{e.message}" }, status: :internal_server_error
    end
  end

  def create
    result = PrepareDocumentUploadToVbms.new(request.parameters, current_user).call

    if result.success?
      render json: { message: "Document successfully queued for upload." }
    else
      render json: result.errors[0], status: :bad_request
    end
  end
end
