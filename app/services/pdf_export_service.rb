# frozen_string_literal: true

class PdfExportService
  S3_BUCKET_NAME = "appeals-status-migrations"
  def call(template_name, object = nil)
    upload_pdf_to_s3(template_name, object)
    S3_BUCKET_NAME
  end

  def create_pdf_from_template(template_name, object = nil)
    kit = PDFKit.new(template_name, :page_size => 'Letter')
    kit.stylesheets << '/app/assets/stylesheets/notification_pdf_style.css'
    pdf = kit.to_pdf
    # INSERT RENDERING STUFF HERE
    pdf
  end

  def upload_pdf_to_s3(template_name, object = nil)
    pdf = create_pdf_from_template(template_name, object)
    filename = Time.zone.now.strftime("ama-migration-%Y-%m-%d--%H-%M.pdf")
    S3Service.store_file(S3_BUCKET_NAME + "/" + filename, pdf)
  end
end
