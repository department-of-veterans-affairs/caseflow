# frozen_string_literal: true

class Form8 < ActiveRecord::Base
  after_initialize :set_version

  # increment whenever a change is made to this class that isn't backwards-compatible with past serialized forms
  # (e.g., changing the type of an attribute from string to date)
  # This is used to force the creation of a new Form8 model from appeal data for any users who are logged in
  # during a deploy with a schema change, so those users won't have certification crash on them.
  # TODO(alex): this should work for the deploy that makes this persisted to the db because we can
  # force creation of db records for all certification models, but will it continue to work for deploys
  # that involve later Form8 migrations?
  SERIALIZATION_VERSION = 2

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
    :ssoc_required,
    :record_other_explanation,
    :remarks,
    :certifying_office,
    :certifying_username,
    :certifying_official_name,
    :certifying_official_title,
    :certification_date
  ].freeze

  # initial form fields, stored in the db for analytics purposes
  # todo alex: commented out fields are commented out because
  # we don't appear to prepopulate them.
  INITIAL_FORM_FIELDS = [
    :_initial_appellant_name,
    :_initial_appellant_relationship,
    :_initial_veteran_name,
    :_initial_insurance_loan_number,
    :_initial_service_connection_for,
    :_initial_service_connection_notification_date,
    :_initial_increased_rating_notification_date,
    :_initial_other_notification_date,
    :_initial_representative_name,
    :_initial_representative_type,
    :_initial_hearing_requested,
    :_initial_contested_claims_procedures_applicable,
    :_initial_contested_claims_requirements_followed,
    :_initial_soc_date
  ].freeze

  def set_version
    self.version = SERIALIZATION_VERSION unless version
  end

  def save_pdf!
    Form8.pdf_service.save_pdf_for!(self)
  end

  # TODO: fix
  def populate_initial_data
  end

  def hearing_on_file
    (hearing_held == "Yes" && hearing_transcript_on_file)
  end

  def increased_rating_for_initial
    increased_rating_for_rolled.initial unless increased_rating_for_rolled.empty?
  end

  def increased_rating_for_rolled
    RolledOverText.new(@increased_rating_for, 2, continued_prepend: "Increased Rating For Continued:")
  end
  private :increased_rating_for_rolled

  def other_for_initial
    other_for_rolled.initial unless other_for_rolled.empty?
  end

  def other_for_rolled
    RolledOverText.new(@other_for, 2, continued_prepend: "Other Continued:")
  end
  private :other_for_rolled

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

  # TODO: alex: remove?
  FORM_FIELDS.each { |field| attr_accessor field }
  INITIAL_FORM_FIELDS.each { |field| attr_accessor field }
  RECORD_TYPE_FIELDS.each { |record_type| attr_accessor record_type[:attribute] }

  attr_accessor :version
  # TODO: alex: remove?
  alias_attribute :id, :vacols_id

  private :service_connection_for_rolled, :remarks_rolled

  def attributes
    record_attrs = RECORD_TYPE_FIELDS.map { |field| field[:attribute] }

    (record_attrs + FORM_FIELDS + [:version]).each_with_object({}) do |field, result|
      result[field] = send(field)
    end.stringify_keys
  end

  def representative
    type = representative_type == "Other" ? representative_type_specify_other : representative_type
    "#{representative_name} - #{type}"
  end

  def pdf_location
    Form8.pdf_service.output_location_for(self)
  end

  def update_from_string_params(params)
    date_fields = [:certification_date, :service_connection_notification_date, :increased_rating_notification_date,
                   :other_notification_date, :soc_date]

    date_fields.each do |f|
      raw_value = params[f]
      params[f] = begin
                    Date.strptime(raw_value, "%m/%d/%Y")
                  rescue
                    nil
                  end if raw_value && raw_value.is_a?(String)
    end

    update(params)
  end

  class << self
    attr_writer :pdf_service

    def pdf_service
      @pdf_service ||= Form8PdfService
    end

    # TODO: alex - remove after we get rid of form8 caching
    def from_string_params(params)
      date_fields = [:certification_date, :service_connection_notification_date, :increased_rating_notification_date,
                     :other_notification_date, :soc_date]

      date_fields.each do |f|
        raw_value = params[f]
        params[f] = begin
                      Date.strptime(raw_value, "%m/%d/%Y")
                    rescue
                      nil
                    end if raw_value && raw_value.is_a?(String)
      end

      Form8.new(params)
    end

    # TODO: alex - remove after we get rid of form8 caching
    def from_session(params)
      return nil if params["version"] != SERIALIZATION_VERSION

      # pass through type-conversion for backwards compatability with improperly serialized forms
      form = from_string_params(params.symbolize_keys)

      # reset
      form.certification_date = Time.zone.now
      form
    end

    def from_appeal(appeal)
      new(
        # TODO: add certification id here
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
