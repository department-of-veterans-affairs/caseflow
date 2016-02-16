class Form8
  include ActiveModel::Model
  include ActiveModel::Conversion
  include ActiveModel::Serialization
  extend ActiveModel::Naming

  attr_accessor :vacols_id, :appellant, :appellant_relationship, :file_number, :veteran_name,
                :insurance_loan_number

  def save!
    Form8.pdf_service.save_form!(form: "VA8", values: serializable_hash)
  end

  def attributes
    {
      "appellant" => appellant,
      "appellant_relationship" => appellant_relationship,
      "file_number" => file_number,
      "veteran_name" => veteran_name,
      "insurance_loan_number" => insurance_loan_number
    }
  end

  class << self
    attr_writer :pdf_service

    def pdf_service
      @pdf_service ||= PdfService
    end

    def new_from_appeal(appeal)
      new(
        vacols_id: appeal.vacols_id,
        appellant: appeal.appellant_name,
        appellant_relationship: appeal.appellant_relationship,
        file_number: appeal.vbms_id,
        veteran_name: appeal.veteran_name,
        insurance_loan_number: appeal.insurance_loan_number
      )
    end
  end
end

class PdfService
  def save_form!(form:, values:)
    # TODO: connect this with pdftk
  end
end
