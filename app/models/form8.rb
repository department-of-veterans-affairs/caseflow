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
    :certifying_office,
    :certifying_username,
    :certifying_official_name,
    :certifying_official_title,
    :certification_date
  ].freeze

  def service_connection_for_rolled
    @service_connection_for_rolled ||= RolledOverText.new(@service_connection_for, 2,
                                                          continued_prepend: "Service Connection For Continued:")
  end

  def service_connection_for_initial
    service_connection_for_rolled.initial unless service_connection_for_rolled.empty?
  end

  def remarks_rolled
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

  attr_reader :remarks, :service_connection_for

  alias_attribute :id, :vacols_id

  private :service_connection_for_rolled, :remarks_rolled

  # override attr writers
  def remarks=(value)
    @remarks = value
    @remarks_rolled = nil
  end

  def service_connection_for=(value)
    @service_connection_for = value
    @service_connection_for_rolled = nil
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

class RolledOverText
  include ActionView::Helpers::TextHelper

  def initialize(raw, max_lines, opts = {})
    @initial_append = " " + (opts[:initial_append] || "(see continued remarks page 2)").strip
    @continued_prepend = "\n \n" + (opts[:continued_prepend] || "Continued:").strip + "\n"
    @max_lines = max_lines
    @max_line_length = opts[:max_line_length] || 101

    parsed = parse_to_array(raw || "")
    @initial = parsed[0]
    @continued = parsed[1]
  end

  attr_reader :initial, :continued

  def rollover?
    !@continued.nil?
  end

  def empty?
    !rollover? && initial.empty?
  end

  private

  def wrap(raw)
    word_wrap(raw, line_width: @max_line_length)
  end

  def rollover_wrapped(wrapped, raw)
    lines = wrapped.split("\n")
    last_line = lines[@max_lines - 1]
    last_line_cutoff_index = @max_line_length - @initial_append.length

    # find last space
    last_line_cutoff_index = last_line.rindex(" ", last_line_cutoff_index) || last_line.length

    # transalte to position in raw
    num_separators = @max_lines - 1
    length_up_to_last_line = lines.slice(0, @max_lines - 1).reduce(0) do |sum, line|
      sum + line.length
    end

    cutoff_index_in_raw = length_up_to_last_line + last_line_cutoff_index + num_separators

    initial = raw[0, cutoff_index_in_raw] + @initial_append
    continued = @continued_prepend + raw[cutoff_index_in_raw + 1, raw.length]

    [initial, continued]
  end

  def rollover_breaking(raw, maxlength)
    initial = "#{raw[0...maxlength]}#{@initial_append}"
    continued = @continued_prepend + raw[maxlength...raw.length]
    [initial, continued]
  end

  def parse_to_array(raw)
    wrapped = wrap(raw)
    num_lines = wrapped.count("\n") + 1
    do_rollover = num_lines > @max_lines
    breaking_maxlength = @max_lines * @max_line_length

    if do_rollover
      rollover_wrapped(wrapped, raw)
    elsif raw.length > breaking_maxlength
      rollover_breaking(raw, breaking_maxlength - @initial_append.length)
    else
      # don't process, will be wrapped in PDF
      [raw, nil]
    end
  end
end
