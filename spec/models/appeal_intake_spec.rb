describe AppealIntake do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let(:user) { Generators::User.build }
  let(:detail) { nil }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:completed_at) { nil }

  let(:intake) do
    AppealIntake.new(
      user: user,
      detail: detail,
      veteran_file_number: veteran_file_number,
      completed_at: completed_at
    )
  end

  context "#review!" do
    subject { intake.review!(request_params) }

    let(:request_params) do
      ActionController::Parameters.new(receipt_date: receipt_date, docket_type: docket_type)
    end

    let(:receipt_date) { "2018-05-25" }
    let(:docket_type) { "hearing" }
    let(:detail) { TemporaryAppeal.new(veteran_file_number: veteran_file_number) }

    it "updates appeal with values" do
      expect(subject).to be_truthy

      expect(intake.detail).to have_attributes(
        receipt_date: Date.new(2018, 5, 25),
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

  context "#complete!" do
    subject { intake.complete!(params) }

    let(:params) do
      { request_issues: [
        { profile_date: "2018-04-30", reference_id: "reference-id", decision_text: "decision text" }
      ] }
    end

    let(:detail) do
      TemporaryAppeal.create!(
        veteran_file_number: "64205555",
        receipt_date: 3.days.ago
      )
    end

    it "completes the intake" do
      subject

      expect(intake.reload).to be_success
      expect(intake.detail.established_at).to_not be_nil
      expect(intake.detail.request_issues.count).to eq 1
      expect(intake.detail.request_issues.first).to have_attributes(
        rating_issue_reference_id: "reference-id",
        rating_issue_profile_date: Date.new(2018, 4, 30),
        description: "decision text"
      )
    end
  end
end
