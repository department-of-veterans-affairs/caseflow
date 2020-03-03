# frozen_string_literal: true

class Form8 < CaseflowRecord
  include UploadableDocument

  FORM8_S3_SUB_BUCKET = "form_8"

  FORM_FIELDS = [
    :vacols_id,
    :appellant_name,
    :appellant_relationship,
    :file_number,
    :veteran_name,
    :insurance_loan_number,
    :service_connection_for,
    :service_connection_notification_date,
    :increased_rating_for,
    :increased_rating_notification_date,
    :other_for,
    :other_notification_date,
    :representative_name,
    :representative_type,
    :representative_type_specify_other,
    :power_of_attorney,
    :power_of_attorney_file,
    :agent_accredited,
    :form_646_of_record,
    :form_646_not_of_record_explanation,
    :hearing_requested,
    :hearing_held,
    :hearing_transcript_on_file,
    :hearing_requested_explanation,
    :contested_claims_procedures_applicable,
    :contested_claims_requirements_followed,
    :soc_date,
    :form9_date,
    :nod_date,
    :ssoc_date_1,
    :ssoc_date_2,
    :ssoc_date_3,
    :ssoc_required,
    :record_other_explanation,
    :remarks,
    :certifying_office,
    :certifying_username,
    :certifying_official_name,
    :certifying_official_title,
    :certifying_official_title_specify_other,
    :certification_date
  ].freeze

  def save_pdf!
    Form8.pdf_service.save_pdf_for!(self)
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/AbcSize
  def assign_attributes_from_appeal(appeal)
    ssoc_dates = appeal.ssoc_dates.present? ? appeal.ssoc_dates.sort : []

    assign_attributes(
      vacols_id: appeal.vacols_id,
      appellant_name: appeal.appellant_name,
      appellant_relationship: appeal.appellant_relationship,
      file_number: appeal.vbms_id,
      veteran_name: appeal.veteran_name,
      insurance_loan_number: appeal.insurance_loan_number,
      service_connection_notification_date: appeal.notification_date,
      increased_rating_notification_date: appeal.notification_date,
      other_notification_date: appeal.notification_date,
      soc_date: appeal.soc_date,
      form9_date: appeal.form9_date,
      nod_date: appeal.nod_date,
      ssoc_date_1: ssoc_dates[0],
      ssoc_date_2: ssoc_dates[1],
      ssoc_date_3: ssoc_dates[2],
      representative_name: appeal.representative_name,
      representative_type: appeal.representative_type,
      hearing_requested: appeal.hearing_requested ? "Yes" : "No",
      hearing_held: appeal.hearing_held ? "Yes" : "No",
      ssoc_required: appeal.ssoc_dates.empty? ? "Not required" : "Required and furnished",
      certifying_office: appeal.regional_office_name,
      certifying_username: appeal.regional_office_key,
      certification_date: Time.zone.now.to_date,
      _initial_appellant_name: appeal.appellant_name,
      _initial_appellant_relationship: appeal.appellant_relationship,
      _initial_veteran_name: appeal.veteran_name,
      _initial_insurance_loan_number: appeal.insurance_loan_number,
      _initial_service_connection_notification_date: appeal.notification_date,
      _initial_increased_rating_notification_date: appeal.notification_date,
      _initial_other_notification_date: appeal.notification_date,
      _initial_representative_name: appeal.representative_name,
      _initial_representative_type: appeal.representative_type,
      _initial_hearing_requested: appeal.hearing_requested ? "Yes" : "No",
      _initial_ssoc_required: appeal.ssoc_dates.empty? ? "Not required" : "Required and furnished"
    )
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  def update_certification_date
    update!(certification_date: Time.zone.now.to_date)
  end

  def hearing_on_file
    (hearing_held == "Yes" && hearing_transcript_on_file)
  end

  def increased_rating_for_initial
    increased_rating_for_rolled.initial unless increased_rating_for_rolled.blank?
  end

  def other_for_initial
    other_for_rolled.initial unless other_for_rolled.blank?
  end

  def service_connection_for_initial
    service_connection_for_rolled.initial unless service_connection_for_rolled.blank?
  end

  def remarks_rollover?
    !rolled_over_fields.empty?
  end

  def remarks_initial
    remarks_rolled.initial unless remarks_rolled.blank?
  end

  def remarks_continued
    rolled_over = rolled_over_fields

    rolled_over.map(&:continued).join unless rolled_over.blank?
  end

  def rolled_over_fields
    [remarks_rolled, service_connection_for_rolled, increased_rating_for_rolled, other_for_rolled].find_all(&:rollover?)
  end

  RECORD_TYPE_FIELDS = [
    { name: "CF OR XCF", attribute: :record_cf_or_xcf },
    { name: "INACTIVE CF", attribute: :record_inactive_cf },
    { name: "DENTAL F", attribute: :record_dental_f },
    { name: "R&E F", attribute: :record_r_and_e_f },
    { name: "TRAINING SUB-F", attribute: :record_training_sub_f },
    { name: "LOAN GUAR. F", attribute: :record_loan_guar_f },
    { name: "OUTPATIENT F", attribute: :record_outpatient_f },
    { name: "HOSPITAL COR", attribute: :record_hospital_cor },
    { name: "CLINICAL REC", attribute: :record_clinical_rec },
    { name: "X-RAYS", attribute: :record_x_rays },
    { name: "SLIDES", attribute: :record_slides },
    { name: "TISSUE BLOCKS", attribute: :record_tissue_blocks },
    { name: "DEP. ED. F (Ch. 35)", attribute: :record_dep_ed_f },
    { name: "INSURANCE F", attribute: :record_insurance_f },
    { name: "OTHER", attribute: :record_other }
  ].freeze

  def attributes
    record_attrs = RECORD_TYPE_FIELDS.map { |field| field[:attribute] }

    (record_attrs + FORM_FIELDS).each_with_object({}) do |field, result|
      result[field] = send(field)
    end.stringify_keys
  end

  def representative
    type = (representative_type == "Other") ? representative_type_specify_other : representative_type
    "#{representative_name} - #{type}"
  end

  def pdf_location
    path = Form8.pdf_service.output_location_for(self)
    fetch_from_s3_and_save(path)
    path
  end

  def source
    "VACOLS"
  end

  def fetch_from_s3_and_save(destination_path)
    S3Service.fetch_file(FORM8_S3_SUB_BUCKET + "/" + pdf_filename, destination_path)
  end

  def pdf_filename
    "form8-#{vacols_id}.pdf"
  end

  def tmp_filename
    "form8-#{vacols_id}.tmp"
  end

  def update_from_string_params(params)
    date_fields = [
      :certification_date,
      :service_connection_notification_date,
      :increased_rating_notification_date,
      :other_notification_date,
      :soc_date
    ]
    date_fields.each do |f|
      raw_value = params[f]
      next unless raw_value&.is_a?(String)

      params[f] = begin
                    Date.strptime(raw_value, "%m/%d/%Y")
                  rescue StandardError
                    nil
                  end
    end
    update(params)
  end

  def document_type
    "Form 8"
  end

  class << self
    attr_writer :pdf_service

    def pdf_service
      @pdf_service ||= Form8PdfService
    end
  end

  private

  def increased_rating_for_rolled
    RolledOverText.new(increased_rating_for, 2, continued_prepend: "Increased Rating For Continued:")
  end

  def other_for_rolled
    RolledOverText.new(other_for, 2, continued_prepend: "Other Continued:")
  end

  def service_connection_for_rolled
    @service_connection_for_rolled = nil if @service_connection_for_rolled &&
                                            @service_connection_for_rolled.raw != @service_connection_for
    @service_connection_for_rolled ||= RolledOverText.new(service_connection_for, 2,
                                                          continued_prepend: "Service Connection For Continued:")
  end

  def remarks_rolled
    @remarks_rolled = nil if @remarks_rolled && @remarks_rolled.raw != @remarks
    @remarks_rolled ||= RolledOverText.new(remarks, 6)
  end
end
