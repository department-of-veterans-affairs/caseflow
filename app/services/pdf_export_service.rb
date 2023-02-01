# frozen_string_literal: true

class PdfExportService
  S3_BUCKET_NAME = "appeals-status-migrations"

  # Purpose: Service that creates pdf file from html template
  #
  # Params: template_name (string), object (json)
  # the object is data that contains
  # Veteran Name (First and Last)
  # Veteran file number
  # Docket Number
  # Docket Type
  # Appeal Stream Type
  # Hearing type
  # Rows of notifications
  # Event type
  # Notification Date
  # Notification Type
  # Recipient Information
  # Status
  # Notification Content
  #
  # Returns: s2 file upload location
  def call(template_name, object = nil)
    upload_pdf_to_s3(template_name, object)
    S3_BUCKET_NAME
  end

  # Purpose: Creates pdf from template using pdfkit
  # Finds and renders the template based on template_name
  # stores created pdf file in s3 bucket
  #
  # Params: template_name (string), object (json)
  #
  # Returns: nil
  def create_store_pdf_from_template(template_name, object = nil)
    # render template
    template = render_to_string :template => "app/views/templates/" + template_name
    # create new pdfkit object from template
    kit = PDFKit.new(template, :page_size => "Letter")
    # add CSS styling
    kit.stylesheets << "/app/assets/stylesheets/notification_pdf_style.css"
    # create file name and file path
    file_name = "test.pdf"
    file_path = "#{Rails.root}/#{file_name}"
    # create pdf file from pdfkit object
    pdf = kit.to_pdf(file_path)
    # store file in s3 bucket
    S3Service.store_file(SchedulePeriod::S3_BUCKET_NAME + "/" + file_name, pdf, :file_path)
  end
end
