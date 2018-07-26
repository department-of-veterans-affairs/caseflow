describe AppealIntake do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
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

  context "#cancel!" do
    subject { intake.cancel!(reason: "system_error", other: nil) }

    let(:detail) do
      Appeal.create!(
        veteran_file_number: "64205555",
        receipt_date: 3.days.ago
      )
    end

    let!(:claimant) do
      Claimant.create!(
        review_request: detail,
        participant_id: "1234"
      )
    end

    it "cancels and deletes the Appeal record created" do
      subject

      expect(intake.reload).to be_canceled
      expect { detail.reload }.to raise_error ActiveRecord::RecordNotFound
      expect(intake).to have_attributes(
        cancel_reason: "system_error",
        cancel_other: nil
      )
      expect { claimant.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context "#review!" do
    subject { intake.review!(request_params) }

    let(:receipt_date) { "2018-05-25" }
    let(:docket_type) { "hearing" }
    let(:claimant) { nil }
    let(:detail) { Appeal.create!(veteran_file_number: veteran_file_number) }

    let(:request_params) do
      ActionController::Parameters.new(receipt_date: receipt_date, docket_type: docket_type, claimant: claimant)
    end

    it "updates appeal with values" do
      expect(subject).to be_truthy

      expect(intake.detail).to have_attributes(
        receipt_date: Date.new(2018, 5, 25),
        docket_type: "hearing"
      )
    end

    it "adds veteran to claimants" do
      expect(subject).to be_truthy

      expect(intake.detail.claimants.count).to eq 1
      expect(intake.detail.claimants.first).to have_attributes(
        participant_id: intake.veteran.participant_id
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

    context "Claimant is different than Veteran" do
      let(:claimant) { "1234" }

      it "adds other relationship to claimants" do
        subject

        expect(intake.detail.claimants.count).to eq 1
        expect(intake.detail.claimants.first).to have_attributes(
          participant_id: "1234"
        )
      end
    end
  end

  context "#complete!" do
    subject { intake.complete!(params) }

    let(:params) do
      { request_issues: [
        { profile_date: "2018-04-30", reference_id: "reference-id", decision_text: "decision text" },
        { decision_text: "non-rated issue decision text",
          issue_category: "test issue category",
          decision_date: "2018-12-25" }
      ] }
    end

    let(:detail) do
      Appeal.create!(
        veteran_file_number: "64205555",
        receipt_date: 3.days.ago
      )
    end

    it "completes the intake" do
      subject

      expect(intake.reload).to be_success
      expect(intake.detail.established_at).to_not be_nil
      expect(intake.detail.request_issues.count).to eq 2
      expect(intake.detail.request_issues.first).to have_attributes(
        rating_issue_reference_id: "reference-id",
        rating_issue_profile_date: Date.new(2018, 4, 30),
        description: "decision text"
      )
      expect(intake.detail.request_issues.second).to have_attributes(
        issue_category: "test issue category",
        decision_date: Date.new(2018, 12, 25),
        description: "non-rated issue decision text"
      )
    end
  end
end
