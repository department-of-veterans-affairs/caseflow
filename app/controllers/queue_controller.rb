class QueueController < ApplicationController
  before_action :react_routed, :check_queue_out_of_service
  before_action :verify_queue_access

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    render "queue/index"
  end

  def dev_document_count
    # only used for local dev. see Appeal.number_of_documents_url
    appeal =
      Appeal.find_by(vbms_id: request.headers["HTTP_FILE_NUMBER"] + "S") ||
      Appeal.find_by(vbms_id: request.headers["HTTP_FILE_NUMBER"] + "C") ||
      Appeal.find_by(vbms_id: request.headers["HTTP_FILE_NUMBER"])
    render json: {
      data: {
        attributes: {
          documents: (1..appeal.number_of_documents).to_a
        }
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: {}, status: 404
  end

  def check_queue_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("queue_out_of_service")
  end
end
