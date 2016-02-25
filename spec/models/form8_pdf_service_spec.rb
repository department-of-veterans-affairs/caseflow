describe Form8PdfService do
  context ".pdf_values_for" do
    let(:form8) do
      Form8.new(
        appellant_name: "Bowie",
        representative_name: "Springsteen",
        representative_type: "Attorney",
        power_of_attorney: "POA",
        ssoc_required: "Required and furnished",
        record_training_sub_f: "1"
      )
    end

    it "returns correctly formatted map of locations to values" do
      expect(Form8PdfService.pdf_values_for(form8)).to eq(
        "form1[0].#subform[0].#area[0].TextField1[0]"  => "Bowie",
        "form1[0].#subform[0].#area[0].TextField1[11]" => "Springsteen - Attorney",
        "form1[0].#subform[0].#area[0].CheckBox21[0]"  => "1",
        "form1[0].#subform[0].#area[0].CheckBox23[12]" => "1",
        "form1[0].#subform[0].#area[0].CheckBox23[20]" => "1"
      )
    end
  end
end
