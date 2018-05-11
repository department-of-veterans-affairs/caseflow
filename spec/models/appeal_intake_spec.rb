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
    subject { intake.review!(request_params) }

    let(:request_params) do
      ActionController::Parameters.new({receipt_date: receipt_date, docket_type: docket_type})
    end

    let(:receipt_date) { "2018-05-25" }
    let(:docket_type) { "hearing" }
    let(:detail) { TemporaryAppeal.new(veteran_file_number: veteran_file_number) }

    it "updates appeal with values" do
      expect(subject).to be_truthy 

      expect(intake.detail).to have_attributes(
        receipt_date: Date.new(2018, 05, 25),
        docket_type: "hearing"
      )
    end

    context "receipt date is blank" do
      let(:receipt_date) { nil }

      it { is_expected.to be_falsey }
    end

    context "docket type is blank" do
      let(:docket_type) { nil }

      it { is_expected.to be_falsey }
    end
  end
end
