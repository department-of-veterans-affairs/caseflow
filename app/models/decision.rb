class Decision < ApplicationRecord
  include UploadableDocument
  belongs_to :appeal
  validates :citation_number, format: { with: /\AA\d{8}\Z/i }

  def document_type
    "BVA Decision"
  end

  def pdf_location
    "/Users/vhaisaroltsa/Desktop/sample.pdf"
  end

  def source
    "VACOLS"
  end
end
