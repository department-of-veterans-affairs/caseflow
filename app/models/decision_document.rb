class DecisionDocument < ApplicationRecord
  include Asyncable
  include UploadableDocument
  
  class NoFileError < StandardError; end

  belongs_to :appeal
  validates :citation_number, format: { with: /\AA\d{8}\Z/i }

  attr_writer :file

  S3_SUB_BUCKET = "decisions".freeze
  DECISION_OUTCODING_DELAY = 3.hours

  def document_type
    "BVA Decision"
  end

  def source
    "BVA"
  end

  # We have to always download the file from s3 to make sure it exists locally
  # instead of storing it on the server and relying that it will be there
  def pdf_location
    S3Service.fetch_file(s3_location, output_location)
    output_location
  end

  def submit_for_processing!
    cache_file!
    super(delay: DECISION_OUTCODING_DELAY)
  end

  def process!
    attempted!
    VBMSService.upload_document_to_vbms(appeal, self)
    processed!

  rescue StandardError => err
    update_error!(err.to_s)
    raise err
  end

  private

  def pdf_name
    appeal.external_id + ".pdf"
  end

  def s3_location
    DecisionDocument::S3_SUB_BUCKET + "/" + pdf_name
  end

  def output_location
    File.join(Rails.root, "tmp", "pdfs", pdf_name)
  end

  def cache_file!
    fail NoFileError unless @file
    S3Service.store_file(s3_location, Base64.decode64(@file))
  end
end
