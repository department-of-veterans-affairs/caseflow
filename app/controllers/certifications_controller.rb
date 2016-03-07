class CertificationsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def new
    if appeal.certified?
      push_ga_event(eventCategory: "Certification", eventLabel: "Already Certified")
      return render "already_certified"
    end

    unless appeal.documents_match?
      push_ga_event(eventCategory: "Certification", eventLabel: "Mismatched Documents")
      return render "mismatched_documents"
    end

    push_ga_event(eventCategory: "Certification", eventLabel: "Initiated")
    @form8 = Form8.from_appeal(appeal)
  end

  def create
    @form8 = Form8.new(params[:form8])
    form8.save!
    redirect_to certification_path(id: form8.id)
  end

  def show
    if params[:confirm]
      push_ga_event(eventCategory: "Certification", eventLabel: "Completed")
      render "confirm"
    end

    push_ga_event(eventCategory: "Certification", eventLabel: "Previewed")
  end

  def pdf
    send_file(form8.pdf_location, type: "application/pdf", disposition: "inline")
  end

  def confirm
    appeal.certify!
    redirect_to certification_path(id: appeal.vacols_id, confirm: true)
  end

  def cancel
    push_ga_event(eventCategory: "Certification", eventLabel: "Canceled")
    render layout: "application"
  end

  private

  def verify_access
    return true if current_user.can_access?(appeal)
    redirect_to "/unauthorized"
  end

  def form8
    @form8 ||= Form8.new(id: params[:id])
  end
  helper_method :form8

  def appeal
    @appeal ||= Appeal.find(params[:id] || params[:vacols_id] || params[:form8][:vacols_id])
  end
  helper_method :appeal
end
