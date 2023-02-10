# frozen_string_literal: true

class PdfExportService
  class << self
    # Purpose: Creates pdf from template using pdfkit
    # Finds and renders the template based on template_name
    # stores created pdf file in s3 bucket
    #
    #
    # Params: template_name (string), object (json)
    # the object is data that contains the appeal
    #
    #
    # Returns: s3 file upload location
    def create_and_save_pdf(template_name, object = nil)
      begin
        # render template
        ac = ActionController::Base.new
        template = ac.render_to_string template: "templates/" + template_name + ".html.erb", layout: false,
                                       locals: { appeal: object }
      # error handling if template doesn't exist
      rescue ActionView::MissingTemplate => error
        Rails.logger.error("PdfExportService::Error - Template does not exist for "\
          "#{template_name} - Error message: #{error}")
        return
      # error handling if template fails to render
      rescue ActionView::Template::Error => error
        Rails.logger.error("PdfExportService::Error - Template failed to render for "\
          "#{template_name} - Error message: #{error}")
        return
      end
      # create new pdfkit object from template
      kit = PDFKit.new(template, page_size: "Letter", margin_top: "0.25in", margin_bottom: "0.25in",
                       margin_left: "0.25in", margin_right: "0.25in")
      # add CSS styling
      stylesheet_name = "app/assets/stylesheets/" + template_name + ".css"
      if File.exist?(stylesheet_name)
        kit.stylesheets << stylesheet_name
      end
      # create file name and file path
      if template_name == "notification_report_pdf_template"
        if object.class.name == "Appeal"
          appeal_id = object.uuid
        elsif object.class.name == "LegacyAppeal"
          appeal_id = object.vacols_id
        end
        file_name = template_name + "_" + appeal_id + ".pdf"
      else
        file_name = template_name + ".pdf"
      end
      # file_location = "#{Rails.root}/#{file_name}"
      # kit.to_pdf(file_location)
      # create pdf file from pdfkit object
      pdf = kit.to_pdf
      # store file in s3 bucket
      file_location = template_name + "/" + file_name
      S3Service.store_file(file_location, pdf)
      file_location
    end
  end
end
