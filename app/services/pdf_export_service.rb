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
      kit.to_pdf
    end
  end
end
