describe Form8PdfService do
  # TODO(alex): this file is undertested. Add more tests
  # as we make modifications to it.

  before do
    @form8 = Form8.new(
      certifying_official_title: "Attorney",
      certifying_official_title_specify_other: "Mugatu"
    )
  end

  context ".pdf_values_for" do
    let(:pdf_values) { Form8PdfService.pdf_values_for(@form8) }

    it "populates values from form8 to pdf" do
      expect(
        pdf_values["form1[0].#subform[0].#area[0].TextField1[21]"]
      ).to eq("Attorney")
    end

    it "uses the other specified title if official title is 'Other'" do
      @form8[:certifying_official_title] = "Other"

      expect(
        pdf_values["form1[0].#subform[0].#area[0].TextField1[21]"]
      ).to eq("Mugatu")
    end
  end
end
