class Decision < ApplicationRecord
  include UploadableDocument
  belongs_to :appeal
  validates :citation_number, format: { with: /\AA\d{8}\Z/i }

  attr_accessor :file

  S3_SUB_BUCKET = "decisions".freeze

  def document_type
    "BVA Decision"
  end

  def pdf_location
    @pdf_location ||= tempfile && tempfile.path
  end

  def source
    "BVA"
  end

  def s3_filename
    appeal.external_id
  end

  def upload!
    return unless file
    S3Service.store_file(Decision::S3_SUB_BUCKET + "/" + s3_filename + ".pdf", pdf_location, :filepath)
    VBMSService.upload_document_to_vbms(appeal, self)
  end

  private

  def tempfile
    pdf = Tempfile.new(["decisions", ".pdf"], encoding: "ascii-8bit")
    pdf.write(Base64.decode64(file))
    pdf.close
    pdf
  end
end
