require "vbms_error"

class CertificationsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  rescue_from VBMSError, with: :on_vbms_error

  def on_vbms_error
    @error_title = "VBMS Failure"
    @error_subtitle = "Unable to communicate with the VBMS system at this time."
    @error_retry_external_service = "VBMS"
    render "errors/500", layout: "application", status: 500
  end

  def new
    @certification = Certification.from_vacols_id!(params[:vacols_id])

    case @certification.start!
    when :already_certified    then render "already_certified"
    when :data_missing         then render "not_ready", status: 409
    when :mismatched_documents then render "mismatched_documents"
    end

    @form8 = @certification.form8(form8_cache_key)
  end

  def create
    @form8 = Form8.from_string_params(params[:form8])
    Rails.cache.write(form8_cache_key, @form8.attributes)
    form8.save!
    redirect_to certification_path(id: form8.id)
  end

  def show
    if params[:confirm]
      push_ga_event(new_ga_event(eventCategory: "Certification", eventAction: "Completed"))
      render "confirm"
    end

    push_ga_event(new_ga_event(eventCategory: "Certification", eventAction: "Previewed"))
  end

  def pdf
    send_file(form8.pdf_location, type: "application/pdf", disposition: "inline")
  end

  def confirm
    appeal.certify!
    redirect_to certification_path(id: appeal.vacols_id, confirm: true)
  end

  def cancel
    push_ga_event(new_ga_event(eventCategory: "Certification", eventAction: "Canceled"))
    render layout: "application"
  end

  private

  def new_ga_event(opts = {})
    { eventLabel: current_user.regional_office, eventValue: appeal.vacols_id }.merge!(opts)
  end

  def form8_cache_key
    # force initialization of cache, there's probably a better way to do this
    session["init"] = true

    "#{session.id}_form8"
  end

  def verify_access
    return true if current_user && current_user.can_access?(appeal) && current_user.can?("Certify Appeal")
    session["return_to"] = request.original_url
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
