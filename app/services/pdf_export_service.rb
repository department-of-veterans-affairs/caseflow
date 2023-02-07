# frozen_string_literal: true

class PdfExportService
  S3_BUCKET_NAME = "appeals-status-migrations"

  # Purpose: Method to be called with an error need to be logged to the rails logger
  #
  # Params: error_message (Expecting a string) - Message to be logged to the logger
  #
  # Response: None
  def log_error(error_message)
    Rails.logger.error(error_message)
  end

  class << self
    # Purpose: Creates pdf from template using pdfkit
    # Finds and renders the template based on template_name
    # stores created pdf file in s3 bucket
    #
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
    # Returns: s3 file upload location
    def create_and_save_pdf(template_name, object = nil)
      begin
        # render template
        ac = ActionController::Base.new
        template = ac.render_to_string template: "templates/" + template_name, layout: false, locals: { object: object }
      # error handling if template doesn't exist
      rescue ActionView::MissingTemplate => error
        log_error("PdfExportService::Error - Template does not exist for name "\
          "#{template_name} - Error message: #{error}")
      # error handling if template fails to render
      rescue ActionView::Template::Error => error
        log_error("PdfExportService::Error - Template failed to render for name "\
          "#{template_name} - Error message: #{error}")
      end
      # create new pdfkit object from template
      kit = PDFKit.new(template, page_size: "Letter")
      # add CSS styling
      kit.stylesheets << "/app/assets/stylesheets/notification_pdf_style.css"
      # create file name and file path
      file_name = "test.pdf"
      file_path = "#{Rails.root}/#{file_name}"
      kit.to_pdf(file_path)
      # create pdf file from pdfkit object
      # pdf = kit.to_pdf
      # # store file in s3 bucket
      # file_location = S3_BUCKET_NAME + "/" + file_name
      # S3Service.store_file(file_location, pdf)
      # file_location
    end
  end
end
