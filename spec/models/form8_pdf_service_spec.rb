require "fileutils"

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

  context ".mark_for_clean" do
    before do
      # delete old clean files
      Dir[Form8PdfService.output_location + "clean-after-*.txt"].each { |file| File.delete(file) }

      FileUtils.cp(
        Rails.root + "spec" + "support" + "form8-TEST.pdf",
        File.join(Form8PdfService.output_location, "form8-TEST.pdf")
      )

      FileUtils.touch(File.join(Form8PdfService.output_location, "TEXT.txt"))

      Timecop.freeze
    end

    after { Timecop.return }

    let(:expected_cleanfile) do
      File.join(Form8PdfService.output_location, "clean-after-#{(Time.zone.now + 1.day).to_i}.txt")
    end

    it "creates clean file with existing files" do
      Form8PdfService.mark_for_clean

      File.open(expected_cleanfile, "r") do |f|
        expect(f.each_line.to_a).to include(File.join(Form8PdfService.output_location, "form8-TEST.pdf\n"))
        expect(f.each_line.to_a).to_not include(File.join(Form8PdfService.output_location, "TEST.txt\n"))
      end
    end
  end

  context ".clean" do
    let(:cleanfile) do
      File.join(Form8PdfService.output_location, "clean-after-#{Time.zone.now.to_i - 1}.txt")
    end

    before do
      FileUtils.cp(
        Rails.root + "spec" + "support" + "form8-TEST.pdf",
        File.join(Form8PdfService.output_location, "form8-TEST.pdf")
      )

      File.open(cleanfile, "w") do |file|
        file.puts File.join(Form8PdfService.output_location, "form8-TEST.pdf")
      end
    end

    it "cleans files recorded on out of date clean-after-*.txt" do
      Form8PdfService.clean

      expect(File.exist?(File.join(Form8PdfService.output_location, "form8-TEST.pdf"))).to be_falsy
      expect(File.exist?(cleanfile)).to be_falsy
    end
  end
end
