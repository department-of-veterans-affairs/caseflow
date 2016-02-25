require 'pdf_forms'

class Form8PdfService
  def self.pdf_forms
    @pdf_forms ||= PdfForms.new("pdftk")
  end

  def self.save_form!(id:, input_pdf_path:, form_values:)
    output_pdf_path = completed_pdf_path(id)

    puts input_pdf_path
    tmp_location = File.join(Rails.root, 'tmp', 'forms', "form8-#{id}.tmp")

    self.pdf_forms.fill_form(
      input_pdf_path,
      tmp_location,
      form_values,
      flatten: true
    )

    # Run it through `pdftk cat`. The reason for this is that editable PDFs have
    # an RSA signature on them which proves they are genuine. pdftk tries to
    # maintain the editability of a PDF after processing it, but then the
    # signature doesn't match. The result is that (without `pdftk cat`) Acrobat
    # shows a warning (other PDF viewers don't care).
    self.pdf_forms.call_pdftk(tmp_location, "cat", "output", output_pdf_path)

    # Remove it from the tmp_location, leaving it only in final_location
    File.delete(tmp_location)

    output_pdf_path
  end

  def self.completed_pdf_path(id)
    absolute_path_of("form8-#{id}.pdf")
  end

  def self.absolute_path_of(file_name)
    File.join(Rails.root, 'tmp', 'forms',  file_name)
  end
end