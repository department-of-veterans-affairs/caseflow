class CertificationsController < ApplicationController
  def new
    @appeal = Appeal.find(params[:vacols_id])
    render "mismatched_documents" unless @appeal.ready_to_certify?
  end
end
