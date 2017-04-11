class CertificationsController < ApplicationController
  before_action :verify_access
  before_action :set_application

  def new
    # NOTE: this isn't rails-restful. certification.start! saves
    # the certification instance.
    status = certification.start!
    @form8 = certification.form8

    if verify_certification_v2_access
      render "v2", layout: "application"
      return
    end

    case status
    when :already_certified    then render "already_certified"
    when :data_missing         then render "not_ready", status: 409
    when :mismatched_documents then render "mismatched_documents"
    end
  end

  # TODO: update for certification v2- should we use hidden form params?
  def create
    # Can't use controller params in model mass assignments without whitelisting. See:
    # http://edgeguides.rubyonrails.org/action_controller_overview.html#strong-parameters
    params.require(:form8).permit!
    form8.update_from_string_params(params[:form8])
    form8.save_pdf!

    redirect_to certification_path(id: certification.form8.vacols_id)
  end

  def show
    render "confirm", layout: "application" if params[:confirm]
  end

  def form9_pdf
    form9 = certification.appeal.form9
    send_file(form9.serve, type: "application/pdf", disposition: "inline")
  end

  def pdf
    send_file(form8.pdf_location, type: "application/pdf", disposition: "inline")
  end

  def confirm
    @certification = Certification.find_by(vacols_id: vacols_id)

    @certification.complete!(current_user.id)

    redirect_to certification_path(id: appeal.vacols_id, confirm: true)
  end

  def set_application
    RequestStore.store[:application] = :certification
  end

  private

  def certification_cancellation
    @certification_cancellation ||= CertificationCancellation.new(certification_id: certification.id)
  end
  helper_method :certification_cancellation

  def verify_access
    verify_authorized_roles("Certify Appeal")
  end

  def verify_certification_v2_access
    return true if current_user && current_user.can?("CertificationV2")
  end

  def certification
    @certification ||= Certification.find_or_create_by_vacols_id(vacols_id)
  end

  def appeal
    @appeal ||= certification.appeal
  end
  helper_method :appeal

  def form8
    @form8 ||= certification.form8
  end
  helper_method :form8

  def vacols_id
    params[:id] || params[:vacols_id] || params[:form8][:vacols_id]
  end

  def logo_name
    "Certification"
  end
end
