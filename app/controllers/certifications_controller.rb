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
    puts "new certification"
    @certification = Certification.from_vacols_id!(vacols_id)

    case @certification.start!
    when :already_certified    then render "already_certified"
    when :data_missing         then render "not_ready", status: 409
    when :mismatched_documents then render "mismatched_documents"
    end

    puts "form 8 cache key"
    puts form8_cache_key

    @form8 = @certification.form8(form8_cache_key)
  end

  def create
    puts "create certification"
    # Can't use controller params in model mass assignments without whitelisting. See:
    # http://edgeguides.rubyonrails.org/action_controller_overview.html#strong-parameters
    params.require(:form8).permit!
    puts "params form8"
    puts params[:form8].inspect
    # creates new form8
    @form8 = Form8.from_string_params(params[:form8])
    Rails.cache.write(form8_cache_key, @form8.attributes)
    form8.save_pdf!
    puts "redirect to certification path"
    redirect_to certification_path(id: form8.id)
  end

  def show
    render "confirm" if params[:confirm]
  end

  def pdf
    send_file(form8.pdf_location, type: "application/pdf", disposition: "inline")
  end

  def confirm
    @certification = Certification.find_by(vacols_id: vacols_id)

    # Account for appeals that don't have a certification record
    # We'll eventually take this split out.
    @certification ? @certification.complete! : appeal.certify!

    redirect_to certification_path(id: appeal.vacols_id, confirm: true)
  end

  def cancel
    render layout: "application"
  end

  private

  # TODO: alex: is this necessary? should it live elsewhere?
  def form8_cache_key
    # force initialization of cache, there's probably a better way to do this
    session["init"] = true

    "#{session.id}_form8"
  end

  def verify_access
    return true if current_user && current_user.can?("Certify Appeal")
    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end

  def certification
    @certification ||= Certification.find_or_create_by_vacols_id(vacols_id)
  end

  def form8
    # Can't use controller params in model mass assignments without whitelisting. See:
    # http://edgeguides.rubyonrails.org/action_controller_overview.html#strong-parameters
    # TODO (alex): is this too permissive
    params.permit!
    @form8 ||= Form8.new(id: params[:id])
  end

  helper_method :form8

  def vacols_id
    params[:id] || params[:vacols_id] || params[:form8][:vacols_id]
  end

  def appeal
    @appeal ||= Appeal.find_or_create_by_vacols_id(vacols_id)
  end
  helper_method :appeal
end
