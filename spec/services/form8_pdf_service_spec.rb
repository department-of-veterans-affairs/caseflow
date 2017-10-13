describe Form8PdfService do
  let(:form8) do
    Form8.new(
      # regular string field
      appellant_name: "Brad Pitt",
      appellant_relationship: "Fancy man",
      file_number: "1234QWERTY",
      veteran_name: "Joe Patriot",
      # hash/selection fields
      power_of_attorney: "POA",
      # date field
      other_notification_date: "2002-11-23T04:05:06+00:00",
      soc_date: "2001-11-23T04:05:06+00:00",
      form9_date: "2003-11-23T04:05:06+00:00",
      ssoc_date_1: "2005-11-24T04:05:06+00:00",
      ssoc_date_2: "2005-11-23T04:05:06+00:00",
      # conditional other field
      certifying_official_title: "Attorney",
      certifying_official_title_specify_other: "Mugatu"
    )
  end

  context ".pdf_values_for_form8" do
    let(:form_fields) { Form8PdfService::FIELD_LOCATIONS_FORM8_V2 }
    let(:pdf_form8_values) do
      Form8PdfService.pdf_values_for(form8, form_fields)
    end

    it "switches to form8_v2 correctly" do
      expect(pdf_form8_values).to include("form1[0].#subform[0].#area[0].TextField1[0]" => "Joe Patriot",
                                          "form1[0].#subform[0].#area[0].TextField1[1]" => "1234QWERTY",
                                          "form1[0].#subform[0].#area[0].TextField1[2]" => "Brad Pitt",
                                          "form1[0].#subform[0].#area[0].Field32[0]" => "11/23/2002",
                                          "form1[0].#subform[0].#area[0].Field32[1]" => "11/23/2001",
                                          "form1[0].#subform[0].#area[0].Field32[2]" => "11/23/2003",
                                          "form1[0].#subform[0].#area[0].Field32[3]" => "11/24/2005",
                                          "form1[0].#subform[0].#area[0].Field32[4]" => "11/23/2005")
    end
  end

  context ".save_pdf_for!" do
    let(:final_location) { Form8PdfService.output_location_for(form8) }

    before do
      Form8PdfService.save_pdf_for!(form8)
    end

    it "should create a file at output location" do
      expect(File.exist?(File.join(Rails.root, "tmp", "pdfs", "form8-#{form8.vacols_id}.pdf"))).to be_truthy
    end

    it "should save a file in s3" do
      path = S3Service.files[form8.pdf_filename]
      expect(path).to_not be nil
      expect(File.exist?(path)).to eq true
    end

    it "should delete temporary file" do
      expect(File.exist?(File.join(Rails.root, "tmp", "pdfs", "form8-#{form8.vacols_id}.tmp"))).to be_falsy
    end
  end
end
