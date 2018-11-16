class Decision < ApplicationRecord
  include UploadableDocument
  belongs_to :appeal
  validates :citation_number, format: { with: /\AA\d{8}\Z/i }

  attr_accessor :file

  S3_SUB_BUCKET = "decisions".freeze

  def document_type
    "BVA Decision"
  end

  # We have to always download the file from s3 to make sure it exists locally
  # instead of storing it on the server and relying that it will be there
  def pdf_location
    S3Service.fetch_file(s3_location, output_location)
    output_location
  end

  def source
    "BVA"
  end

  def upload!
    return unless file
    S3Service.store_file(s3_location, Base64.decode64(file))
    VBMSService.upload_document_to_vbms(appeal, self)
  end

  def s3_location
    Decision::S3_SUB_BUCKET + "/" + pdf_name
  end

  private

  def pdf_name
    appeal.external_id + ".pdf"
  end

  def output_location
    File.join(Rails.root, "tmp", "pdfs", pdf_name)
  end
end
