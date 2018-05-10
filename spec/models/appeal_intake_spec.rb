describe AppealIntake do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let(:user) { Generators::User.build }
  let(:detail) { nil }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }

  let(:intake) do
    AppealIntake.new(
      user: user,
      detail: detail,
      veteran_file_number: veteran_file_number
    )
  end

  context "#review!" do
    it "updates appeal with values" do
      expect(subject).to be_truthy 

      expect(intake.detail).to have_attributes(
        receipt_date: "",
        docket_type: ""
      )
    end

    context "receipt date is blank" do
      it { is_expected.to be_falsey }
    end

    context "docket type is blank" do
      it { is_expected.to be_falsey }
    end
  end
end
