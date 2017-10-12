# frozen_string_literal: true
require "pdf_forms"

class Form8PdfService
  PDF_PAGE_1 = "form1[0].#subform[0].#area[0].".freeze
  PDF_PAGE_2 = "form1[0].#subform[1].".freeze

  # Currently, the only thing on Page 2 of the VA Form 8 is the continued
  # remarks. As a result, we'll just say anything except for that is actually
  # on Page 1.
  FIELD_PAGES = Hash.new PDF_PAGE_1
  FIELD_PAGES[:remarks_continued] = PDF_PAGE_2

  FIELD_LOCATIONS_FORM8_V2 = {
    veteran_name: "TextField1[0]",
    file_number: "TextField1[1]",
    appellant_name: "TextField1[2]",
    insurance_loan_number: "TextField1[3]",
    # TODO: add "notification date" as a DB field,
    # remove the v1 form8 notification fields,
    # and continue.
    other_notification_date: "Field32[0]",
    soc_date: "Field32[1]",
    form9_date: "Field32[2]",
    ssoc_date_1: "Field32[3]",
    ssoc_date_2: "Field32[4]",
    ssoc_date_3: "Field32[5]",
    representative: "TextField1[4]",
    hearing_preference: {
      "HEARING_CANCELLED" => "CheckBox21[0]",
      "NO_HEARING_DESIRED" => "CheckBox21[0]",
      "HEARING_TYPE_NOT_SPECIFIED" => "CheckBox21[1]",
      "VIDEO" => "CheckBox21[1]",
      "WASHINGTON_DC" => "CheckBox21[2]",
      "TRAVEL_BOARD" => "CheckBox21[3]",
      "NO_BOX_SELECTED" => "CheckBox21[4]"
    },
    remarks_initial: "TextField1[5]",
    remarks_continued: "TextField1[14]",
    certifying_office: "TextField1[6]",
    certifying_username: "TextField1[7]",
    certifying_official_name: "TextField1[8]",
    certifying_official_title: "TextField1[9]",
    certification_date: "TextField1[10]"
  }.freeze

  PDF_CHECKBOX_SYMBOL = "1".freeze

  # Rubocop complains about the number of conditions here,
  # but IMO it's pretty clear and I don't want to break it up
  # just for the sake of it.
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def self.pdf_values_for(form8, field_locations)
    field_locations.each_with_object({}) do |(attribute, location), pdf_values|
      next pdf_values unless (value = form8.send(attribute))

      if attribute == :certifying_official_title && value == "Other"
        # Most instances of "#{field_name}_other" come straight from
        # the form8, but we added the radio buttons for question 17B
        # to Caseflow even though the Form 8 has no corresponding
        # buttons. So the user selected "Other" instead of one of the
        # radio button values, fill the pdf field with the
        # user-entered value.
        value = form8[:certifying_official_title_specify_other]
      end

      if value.is_a?(Date) || value.is_a?(Time)
        value = value.to_formatted_s(:short_date)
      end

      if location.is_a?(Hash)
        location = location[value]
        value = PDF_CHECKBOX_SYMBOL
      end

      location = FIELD_PAGES[attribute] + location

      pdf_values[location] = value
    end
  end

  def self.save_pdf_for!(form8)
    tmp_location = tmp_location_for(form8)
    final_location = output_location_for(form8)

    File.delete(tmp_location) if File.exist?(tmp_location)

    pdf_forms.fill_form(
      empty_pdf_location("VA8_v2.pdf"),
      tmp_location,
      pdf_values_for(form8, FIELD_LOCATIONS_FORM8_V2),
      flatten: true
    )

    File.delete(final_location) if File.exist?(final_location)

    # Run it through `pdftk cat`. The reason for this is that editable PDFs have
    # an RSA signature on them which proves they are genuine. pdftk tries to
    # maintain the editability of a PDF after processing it, but then the
    # signature doesn't match. The result is that (without `pdftk cat`) Acrobat
    # shows a warning (other PDF viewers don't care).
    pdf_forms.call_pdftk(
      tmp_location,
      "cat",
      "output",
      final_location
    )

    S3Service.store_file(form8.pdf_filename, final_location, :filepath)

    # Remove it from the tmp_location, leaving it only in final_location
    File.delete(tmp_location)
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/MethodLength

  def self.output_location_for(form8)
    File.join(Rails.root, "tmp", "pdfs", form8.pdf_filename)
  end

  def self.tmp_location_for(form8)
    File.join(Rails.root, "tmp", "pdfs", form8.tmp_filename)
  end

  def self.empty_pdf_location(file_name)
    File.join(Rails.root, "lib", "pdfs", file_name)
  end

  def self.pdf_forms
    # from the pdf-forms readme: XFDF is supposed to have
    # better support for non-western encodings
    @pdf_forms ||= PdfForms.new("pdftk", data_format: "XFdf")
  end
end
