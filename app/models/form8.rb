class Form8
  include ActiveModel::Model
  include ActiveModel::Conversion
  include ActiveModel::Serialization
  extend ActiveModel::Naming

  FORM_FIELDS = [
    :vacols_id, :appellant, :appellant_relationship, :file_number, :veteran_name,
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
    :hearing_requested
  ].freeze

  FORM_FIELDS.each { |field| attr_accessor field }

  def save!
    Form8.pdf_service.save_form!(form: "VA8", values: serializable_hash)
  end

  def attributes
    FORM_FIELDS.each_with_object({}) do |field, attributes_hash|
      attributes_hash[field.to_s] = send(field)
    end
  end

  class << self
    attr_writer :pdf_service

    def pdf_service
      @pdf_service ||= PdfService
    end

    # TODO: test me.
    def new_from_appeal(appeal)
      new(
        vacols_id: appeal.vacols_id,
        appellant: appeal.appellant_name,
        appellant_relationship: appeal.appellant_relationship,
        file_number: appeal.vbms_id,
        veteran_name: appeal.veteran_name,
        insurance_loan_number: appeal.insurance_loan_number,
        service_connection_nod_date: appeal.nod_date,
        increased_rating_nod_date: appeal.nod_date,
        other_nod_date: appeal.nod_date
      )
    end
  end
end

class PdfService
  def save_form!(form:, values:)
    # TODO: connect this with pdftk
  end
end
