module UploadableDocument
  extend ActiveSupport::Concern

  def document_type_id
    Document.type_id(document_type) || fail("#{document_type} is not recognized in Document.")
  end

  # :nocov:
  def upload_date
    Time.zone.now
  end

  def document_type
    fail "#{self.class} is missing document_type"
  end

  def pdf_location
    fail "#{self.class} is missing pdf_location"
  end
  # :nocov:
end
