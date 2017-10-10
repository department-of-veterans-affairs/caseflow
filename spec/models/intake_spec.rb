describe Intake do
  let(:veteran_file_number) { "64205050" }

  let(:intake) do
    Intake.new(veteran_file_number: veteran_file_number)
  end

  let!(:veteran) { Generators::Veteran.build(file_number: "64205050") }

  context "#valid_to_start?" do
    subject { intake.valid_to_start? }

    context "veteran_file_number is null" do
      let(:veteran_file_number) { nil }

      it "adds invalid_file_number and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq(:invalid_file_number)
      end
    end

    context "veteran_file_number has less than 8 digits" do
      let(:veteran_file_number) { "1111222" }

      it "adds invalid_file_number and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq(:invalid_file_number)
      end
    end

    context "veteran_file_number has non-digit characters" do
      let(:veteran_file_number) { "HAXHAXHAX" }

      it "adds invalid_file_number and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq(:invalid_file_number)
      end
    end

    context "veteran not found in bgs" do
      let(:veteran_file_number) { "11111111" }

      it "adds veteran_not_found and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq(:veteran_not_found)
      end
    end

    context "veteran not accessible by user" do
      before do
        Fakes::BGSService.inaccessible_appeal_vbms_ids = [veteran_file_number]
      end

      it "adds veteran_not_accessible and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq(:veteran_not_accessible)
      end
    end

    context "when number is valid (even with extra spaces)" do
      let(:veteran_file_number) { "  64205050  " }
      it { is_expected.to be_truthy }
    end
  end
end
