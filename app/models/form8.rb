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
    { name: "DEP. ED. F (Ch. 35", attribute: :record_dep_ed_f },
    { name: "INSURANCE F", attribute: :record_insurance_f },
    { name: "OTHER", attribute: :record_other }
  ].freeze

  PDF_FIELDS = {
    :appellant_name => "form1[0].#subform[0].#area[0].TextField1[0]",
    :appellant_relationship => "form1[0].#subform[0].#area[0].TextField1[1]",
    :file_number => "form1[0].#subform[0].#area[0].TextField1[2]",
    :veteran_name => "form1[0].#subform[0].#area[0].TextField1[3]",
    :insurance_loan_number => "form1[0].#subform[0].#area[0].TextField1[4]",
    :service_connection_for => "form1[0].#subform[0].#area[0].TextField1[5]",
    :service_connection_nod_date => "form1[0].#subform[0].#area[0].TextField1[6]",
    :increased_rating_for => "form1[0].#subform[0].#area[0].TextField1[7]",
    :increased_rating_nod_date => "form1[0].#subform[0].#area[0].TextField1[8]",
    :other_for => "form1[0].#subform[0].#area[0].TextField1[9]",
    :other_nod_date => "form1[0].#subform[0].#area[0].TextField1[10]",
    :representative_name => "form1[0].#subform[0].#area[0].TextField1[11]",
    :representative_type => "form1[0].#subform[0].#area[0].TextField1[11]",
    :representative_type_specify_other => "form1[0].#subform[0].#area[0].TextField1[12]",

    :power_of_attorney => {
        "POA"=>"form1[0].#subform[0].#area[0].CheckBox21[0]",
        "Certification that valid POA is in another VA file"=>"form1[0].#subform[0].#area[0].CheckBox21[1]"
    },

    :agent_accredited => {
        "Yes"=> "form1[0].#subform[0].#area[0].CheckBox23[0]",
        "No" => "form1[0].#subform[0].#area[0].CheckBox23[1]"
    },

    :form_646_of_record => {
        "Yes" => "form1[0].#subform[0].#area[0].CheckBox23[2]",
        "No" => "form1[0].#subform[0].#area[0].CheckBox23[3]"
    },

    :form_646_not_of_record_explaination => "form1[0].#subform[0].#area[0].TextField1[13]",

    :hearing_requested => {
        "Yes" => "form1[0].#subform[0].#area[0].CheckBox23[4]",
        "No" => "form1[0].#subform[0].#area[0].CheckBox23[5]"
    },

    :hearing_transcript_on_file => {
        "Yes" => "form1[0].#subform[0].#area[0].CheckBox23[6]",
        "No" => "form1[0].#subform[0].#area[0].CheckBox23[7]"
    },

    :hearing_requested_explaination => "form1[0].#subform[0].#area[0].TextField1[14]",

    :contested_claims_procedures_applicable => {
        "Yes" => "form1[0].#subform[0].#area[0].CheckBox23[8]",
        "No" => "form1[0].#subform[0].#area[0].CheckBox23[9]"
    },

    :contested_claims_requirements_followed => {
        "Yes" => "form1[0].#subform[0].#area[0].CheckBox23[10]",
        "No" => "form1[0].#subform[0].#area[0].CheckBox23[11]"
    },

    :soc_date => "form1[0].#subform[0].#area[0].TextField1[15]",

    :ssoc_required => {
        "Yes" => "form1[0].#subform[0].#area[0].CheckBox23[12]",
        "No" => "form1[0].#subform[0].#area[0].CheckBox23[13]"
    },

    :record_cf_or_xcf => "form1[0].#subform[0].#area[0].CheckBox23[14]",
    :record_inactive_cf => "form1[0].#subform[0].#area[0].CheckBox23[19]",
    :record_dental_f => "form1[0].#subform[0].#area[0].CheckBox23[25]",
    :record_r_and_e_f => "form1[0].#subform[0].#area[0].CheckBox23[15]",
    :record_training_sub_f => "form1[0].#subform[0].#area[0].CheckBox23[20]",
    :record_loan_guar_f => "form1[0].#subform[0].#area[0].CheckBox23[16]",
    :record_outpatient_f => "form1[0].#subform[0].#area[0].CheckBox23[17]",
    :record_hospital_cor => "form1[0].#subform[0].#area[0].CheckBox23[22]",
    :record_clinical_rec => "form1[0].#subform[0].#area[0].CheckBox23[26]",
    :record_x_rays => "form1[0].#subform[0].#area[0].CheckBox23[18]",
    :record_slides => "form1[0].#subform[0].#area[0].CheckBox23[23]",
    :record_tissue_blocks => "form1[0].#subform[0].#area[0].CheckBox23[27]",
    :record_dep_ed_f => "form1[0].#subform[0].#area[0].CheckBox23[24]",
    :record_insurance_f => "form1[0].#subform[0].#area[0].CheckBox23[21]",
    :record_other => "form1[0].#subform[0].#area[0].CheckBox23[28]",
    :record_other_explaination => "form1[0].#subform[0].#area[0].TextField1[16]",
    :remarks => "form1[0].#subform[0].#area[0].TextField1[17]",
    :certifying_office => "form1[0].#subform[0].#area[0].TextField1[18]",
    :certifying_username => "form1[0].#subform[0].#area[0].TextField1[19]",
    :certifying_official_name => "form1[0].#subform[0].#area[0].TextField1[20]",
    :certifying_official_title => "form1[0].#subform[0].#area[0].TextField1[21]",
    :certification_date => "form1[0].#subform[0].#area[0].TextField1[22]"
  }.freeze

  attr_accessor :id
  FORM_FIELDS.each { |field| attr_accessor field }
  RECORD_TYPE_FIELDS.each { |record_type| attr_accessor record_type[:attribute] }

  def save!
    @id = vacols_id
    empty_form =  File.join(Rails.root, "lib/pdfs/VA8.pdf")
    @pdf_path = Form8.pdf_service.save_form!(id: @id,
                                             input_pdf_path: empty_form,
                                             form_values: Form8.to_pdf_values(serializable_hash))
  end

  PDF_CHECKBOX_SYMBOL = "1"

  def self.to_pdf_values(form_values)
    vals = form_values.reduce({}) {|memo, (key,value)|
      translated_to = PDF_FIELDS[key.to_sym]

      if translated_to.is_a?(Hash)
        translated_to = translated_to[value]
        value = PDF_CHECKBOX_SYMBOL
      end

      if not translated_to.nil?

        # if more than one field maps, save in a list and concatenate later
        if memo.has_key?(translated_to)
          memo[translated_to] = [*memo[translated_to], value]
        else
          memo[translated_to] = value
        end
      end

      memo
    }

    # concat multi-vals
    joiners = {:representative_name=> " - "}

    joiners.each {|key,joiner|
      vals[PDF_FIELDS[key]] = vals[PDF_FIELDS[key]].join(joiner)
    }

    # make checkboxes true
    RECORD_TYPE_FIELDS.each { |field|
      key = PDF_FIELDS[field[:attribute]]

      if vals[key] == "1"
        vals[key] = PDF_CHECKBOX_SYMBOL
      else
        vals.delete(key)
      end
    }

    vals
  end

  def attributes
    attrs = FORM_FIELDS.each_with_object({}) do |field, attributes_hash|
      attributes_hash[field.to_s] = send(field)
    end

    RECORD_TYPE_FIELDS.each do |record_type|
      attrs[record_type[:attribute].to_s] = send(record_type[:attribute])
    end

    attrs
  end

  def persisted?
    false
  end

  def pdf_location
    Form8.pdf_service.completed_pdf_path(id)
  end

  class << self
    attr_writer :pdf_service

    def pdf_service
      @pdf_service ||= Form8PdfService
    end

    def new_from_appeal(appeal)
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
        certifying_office: "PLACEHOLDER",
        certifying_username: "PLACEHOLDER",
        certification_date: Time.zone.now
      )
    end
  end
end