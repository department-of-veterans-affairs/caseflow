# frozen_string_literal: true

class Form8
  include ActiveModel::Model
  include ActiveModel::Conversion
  include ActiveModel::Serialization
  extend ActiveModel::Naming

  FORM_FIELDS = [
    :vacols_id,
    :appellant_name,
    :appellant_relationship,
    :file_number,
    :veteran_name,
    :insurance_loan_number,
    :service_connection_for,
    :service_connection_nod_date,
    :increased_rating_for,
    :increased_rating_nod_date,
    :other_for,
    :other_nod_date,
    :representative_name,
    :representative_type,
    :representative_type_specify_other,
    :power_of_attorney,
    :power_of_attorney_file,
    :agent_accredited,
    :form_646_of_record,
    :form_646_not_of_record_explaination,
    :hearing_requested,
    :hearing_transcript_on_file,
    :hearing_requested_explaination,
    :contested_claims_procedures_applicable,
    :contested_claims_requirements_followed,
    :soc_date,
    :ssoc_required,
    :record_other_explaination,
    :remarks,
    :certifying_office,
    :certifying_username,
    :certifying_official_name,
    :certifying_official_title,
    :certification_date
  ].freeze

  def service_connection_for_rolled
    @service_connection_for_rolled = nil if @service_connection_for_rolled &&
                                            @service_connection_for_rolled.raw != @service_connection_for
    @service_connection_for_rolled ||= RolledOverText.new(@service_connection_for, 2,
                                                          continued_prepend: "Service Connection For Continued:")
  end

  def service_connection_for_initial
    service_connection_for_rolled.initial unless service_connection_for_rolled.empty?
  end

  def remarks_rolled
    @remarks_rolled = nil if @remarks_rolled && @remarks_rolled.raw != @remarks
    @remarks_rolled ||= RolledOverText.new(@remarks, 6)
  end

  def remarks_rollover?
    !rolled_over_fields.empty?
  end

  def remarks_initial
    remarks_rolled.initial unless remarks_rolled.empty?
  end

  def remarks_continued
    rolled_over = rolled_over_fields

    rolled_over.map(&:continued).join unless rolled_over.empty?
  end

  def rolled_over_fields
    [remarks_rolled, service_connection_for_rolled].find_all(&:rollover?)
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

  FORM_FIELDS.each { |field| attr_accessor field }
  RECORD_TYPE_FIELDS.each { |record_type| attr_accessor record_type[:attribute] }

  alias_attribute :id, :vacols_id

  private :service_connection_for_rolled, :remarks_rolled

  def attributes
    record_attrs = RECORD_TYPE_FIELDS.map { |field| field[:attribute] }

    (record_attrs + FORM_FIELDS).each_with_object({}) do |field, result|
      result[field] = send(field)
    end
  end

  def representative
    type = representative_type == "Other" ? representative_type_specify_other : representative_type
    "#{representative_name} - #{type}"
  end

  def save!
    Form8.pdf_service.save_pdf_for!(self)
  end

  def persisted?
    false
  end

  def pdf_location
    Form8.pdf_service.output_location_for(self)
  end

  class << self
    attr_writer :pdf_service

    def pdf_service
      @pdf_service ||= Form8PdfService
    end

    def from_appeal(appeal)
      new(
        vacols_id: appeal.vacols_id,
        appellant_name: appeal.appellant_name,
        appellant_relationship: appeal.appellant_relationship,
        file_number: appeal.vbms_id,
        veteran_name: appeal.veteran_name,
        insurance_loan_number: appeal.insurance_loan_number,
        service_connection_nod_date: appeal.nod_date,
        increased_rating_nod_date: appeal.nod_date,
        other_nod_date: appeal.nod_date,
        soc_date: appeal.soc_date,
        representative_name: appeal.representative_name,
        representative_type: appeal.representative_type,
        hearing_requested: appeal.hearing_type ? "Yes" : "No",
        ssoc_required: appeal.ssoc_dates.empty? ? "Not required" : "Required and furnished",
        certifying_office: appeal.regional_office_name,
        certifying_username: appeal.regional_office_key,
        certification_date: Time.zone.now
      )
    end
  end
end
