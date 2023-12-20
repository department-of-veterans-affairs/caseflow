# frozen_string_literal: true

class CertificationsController < ApplicationController
  before_action :verify_access, :check_certification_out_of_service

  def new
    certification.async_start!
    react_routed
    render "v2", layout: "application"
  end

  def update_certification_from_v2_form
    permitted = params
      .require("update")
      .permit("representative_name",
              "representative_type",
              "poa_matches",
              "poa_correct_in_vacols",
              "poa_correct_in_bgs",
              "hearing_change_doc_found_in_vbms",
              "form9_type",
              "hearing_preference",
              "certifying_official_name",
              "certifying_official_title")
    certification.update!(permitted)
  end

  def update_v2
    update_certification_from_v2_form
    render json: {}
  end

  def certify_v2
    update_certification_from_v2_form
    validate_data_presence_v2

    if %w[NO_HEARING_DESIRED NO_BOX_SELECTED HEARING_CANCELLED].include?(certification.hearing_preference)
      hearing_requested = "No"
    else
      hearing_requested = "Yes"
    end

    form8.update_from_string_params(
      representative_type: certification.rep_type,
      representative_name: certification.rep_name,
      hearing_preference: certification.hearing_preference,
      # This field is necessary when on v2 certification but v1 form8
      hearing_requested: hearing_requested,
      certifying_official_name: certification.certifying_official_name,
      certifying_official_title: certification.certifying_official_title
    )
    form8.save_pdf!
    certification.complete!(current_user.id)
    render json: {}
  end

  def show
    certification_data
  end

  def certification_data
    return render json: { loading_data_failed: true } if certification.loading_data_failed
    return render json: { loading_data: true } if certification.loading_data

    render json: { certification: certification.to_hash, form9PdfPath: form9_pdfjs_path }
  end

  def form9_pdf
    form9 = certification.appeal.form9
    send_file(form9.serve, type: "application/pdf", disposition: "inline")
  end

  def form9_pdfjs_path
    pdfjs.full_path(file: form9_pdf_certification_path(id: certification.vacols_id))
  end

  def pdf
    send_file(form8.pdf_location, type: "application/pdf", disposition: "inline")
  end

  def set_application
    RequestStore.store[:application] = :certification
  end

  private

  def check_certification_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("certification_out_of_service")
  end

  # Make sure all data is there in case user skips steps and goes straight to sign_and_certify
  def validate_data_presence_v2
    fail Caseflow::Error::CertificationMissingData unless check_confirm_hearing_data
  end

  def check_confirm_hearing_data
    certification.hearing_preference
  end

  def certification_cancellation
    @certification_cancellation ||= CertificationCancellation.new(certification_id: certification.id)
  end
  helper_method :certification_cancellation

  def verify_access
    verify_authorized_roles("Certify Appeal")
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
