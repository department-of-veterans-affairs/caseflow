class CertificationsController < ApplicationController
  before_action :verify_authentication

  def new
    render "mismatched_documents" unless appeal.ready_to_certify?
    @form8 = Form8.new_from_appeal(appeal)
  end

  def create
    @form8 = Form8.new(params[:form8])
    @form8.save!
    redirect_to certification_path(@form8)
  end

  def show
  end

  def pdf
    send_file(form8.pdf_location, type: 'application/pdf', disposition: 'inline')
  end

  private

  def form8
    @form8 ||= Form8.new(id: params[:id])
  end
  helper_method :form8

  def appeal
    @appeal ||= Appeal.find(params[:id] || params[:vacols_id] || params[:form8][:vacols_id])
  end
  helper_method :appeal
end
