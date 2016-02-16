class Form8
  include ActiveModel::Model
  include ActiveModel::Conversion
  include ActiveModel::Serialization
  extend ActiveModel::Naming

  attr_accessor :vacols_id, :appellant, :appellant_relationship, :file_number

  def save!
    Form8.pdf_service.save_form!(form: "VA8", values: serializable_hash)
  end

  def attributes
    {
      "appellant" => appellant,
      "appellant_relationship" => appellant_relationship,
      "file_number" => file_number
    }
  end

  class << self
    attr_writer :pdf_service

    def pdf_service
      @pdf_service ||= PdfService.new
    end

    def new_from_appeal(appeal)
      new(
        vacols_id: appeal.vacols_id,
        appellant: appeal.correspondent.appellant_name,
        appellant_relationship: appeal.correspondent.appellant_relationship,
        file_number: appeal.vbms_id
      )
    end
  end
end

class PdfService
  def save_form!(form:, values:)
    # TODO: connect this with pdftk
  end
end
