class ReviewController < ApplicationController
  before_action :verify_system_admin

  def index
    vacols_id = params[:vacols_id]
    @appeal = Appeal.find_or_create_by_vacols_id(vacols_id)
  end

  def logo_name
    "Decision"
  end

  def show
    @document = Document.find(params[:id])
  end

  # TODO: Scope this down so that users can only see documents
  # associated with assigned appeals
  def pdf
    document = Document.find(params[:id])

    # The line below enables document caching for 12 hours. It's best to disable
    # this while we're still developing.
    # expires_in 12.hours, :public => true
    send_file(
      document.serve,
      type: "application/pdf",
      disposition: "inline")
  end
end
