class CertificationsController < ApplicationController
  def new
    render "mismatched_documents" unless appeal.ready_to_certify?
    @form8 = Form8.new_from_appeal(appeal)
  end

  def create
    @form8 = Form8.new(params[:form8])
    @form8.save!
  end

  private

  def appeal
    @appeal ||= Appeal.find(params[:vacols_id] || params[:form8][:vacols_id])
  end
  helper_method :appeal
end
