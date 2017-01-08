describe Form8PdfService do
  # TODO(alex): this file is undertested. Add more tests
  # as we make modifications to it.
  let(:form8) do
    Form8.new(
      certifying_official_title: "Attorney",
      certifying_official_title_specify_other: "Mugatu"
    )
  end

  context ".pdf_values_for" do

    let(:pdf_form8_values) do
      Form8PdfService.pdf_values_for(form8)
    end

    it "goes through the fields" do
      Form8::FORM_FIELDS.each do |field|
        form8[field] = (0...8).map { (65 + rand(26)).chr }.join

      end
    end

    it "populates values from form8 to pdf" do
      expect(
        pdf_form8_values["form1[0].#subform[0].#area[0].TextField1[21]"]
      ).to eq("Attorney")
    end

    it "uses the other specified title if official title is 'Other'" do
      form8[:certifying_official_title] = "Other"

      expect(
        pdf_form8_values["form1[0].#subform[0].#area[0].TextField1[21]"]
      ).to eq("Mugatu")
    end

  end

  context ".save_pdf_for!" do
    let(:final_location) { Form8PdfService.output_location_for(form8) }

    before do
      Form8PdfService.save_pdf_for!(form8)
    end

    it "should have a file at output location" do
      expect(File.exists?(File.join(Rails.root, "tmp", "pdfs", "form8-#{form8.vacols_id}.pdf"))).to be_truthy
    end

    it "should not leave file at temporary location" do
      expect(File.exists?(File.join(Rails.root, "tmp", "pdfs", "form8-#{form8.vacols_id}.tmp"))).to be_falsy
    end
  end


end
