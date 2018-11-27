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
        participant_id: "1234",
        payee_code: "10"
      )
    end

    let!(:request_issue) do
      RequestIssue.new(
        review_request: detail,
        rating_issue_profile_date: Time.zone.local(2018, 4, 30),
        rating_issue_reference_id: "issue1",
        contention_reference_id: "1234",
        description: "description"
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
      expect { request_issue.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context "#review!" do
    subject { intake.review!(request_params) }

    let(:receipt_date) { "2018-05-25" }
    let(:docket_type) { "hearing" }
    let(:claimant) { nil }
    let(:payee_code) { nil }
    let(:legacy_opt_in_approved) { true }
    let(:veteran_is_not_claimant) { "false" }
    let(:detail) { Appeal.create!(veteran_file_number: veteran_file_number) }

    let(:request_params) do
      ActionController::Parameters.new(
        receipt_date: receipt_date,
        docket_type: docket_type,
        claimant: claimant,
        payee_code: payee_code,
        legacy_opt_in_approved: legacy_opt_in_approved,
        veteran_is_not_claimant: veteran_is_not_claimant
      )
    end

    it "updates appeal with values" do
      expect(subject).to be_truthy

      expect(intake.detail).to have_attributes(
        receipt_date: Date.new(2018, 5, 25),
        docket_type: "hearing",
        legacy_opt_in_approved: true,
        veteran_is_not_claimant: false
      )
    end

    it "adds veteran to claimants" do
      expect(subject).to be_truthy

      expect(intake.detail.claimants.count).to eq 1
      expect(intake.detail.claimants.first).to have_attributes(
        participant_id: intake.veteran.participant_id,
        payee_code: nil
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
      let(:payee_code) { "10" }
      let(:veteran_is_not_claimant) { "true" }

      it "adds other relationship to claimants" do
        subject

        expect(intake.detail.claimants.count).to eq 1
        expect(intake.detail.claimants.first).to have_attributes(
          participant_id: "1234",
          payee_code: nil
        )
      end

      context "claimant is nil" do
        let(:claimant) { nil }
        let(:receipt_date) { 3.days.from_now }

        it "is expected to add an error that claimant cannot be blank" do
          expect(subject).to be_falsey
          expect(detail.errors[:claimant]).to include("blank")
          expect(detail.errors[:receipt_date]).to include("in_future")
          expect(detail.claimants).to be_empty
        end
      end
    end
  end

  context "#complete!" do
    subject { intake.complete!(params) }

    let(:params) do
      { request_issues: [
        { profile_date: "2018-04-30", reference_id: "reference-id", decision_text: "decision text" },
        { decision_text: "nonrating request issue decision text",
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
        rating_issue_profile_date: Time.zone.local(2018, 4, 30),
        description: "decision text"
      )
      expect(intake.detail.request_issues.second).to have_attributes(
        issue_category: "test issue category",
        decision_date: Date.new(2018, 12, 25),
        description: "nonrating request issue decision text"
      )
      expect(intake.detail.tasks.count).to eq 1
    end
  end
end
