describe RampIntake do
  let(:intake) do
    RampIntake.new(veteran_file_number: "64205555")
  end

  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }

  context "#valid_to_start?" do
    subject { intake.valid_to_start? }

    context "there is not a ramp election for veteran" do
      it "adds didnt_receive_ramp_election and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq(:didnt_receive_ramp_election)
      end
    end

    context "there is a ramp election for veteran" do
      let!(:ramp_election) { RampElection.create!(veteran_file_number: "64205555") }
      it { is_expected.to eq(true) }
    end
  end
end
