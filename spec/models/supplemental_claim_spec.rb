describe SupplementalClaim do
  before do
    FeatureToggle.enable!(:intake_legacy_opt_in)
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:intake_legacy_opt_in)
  end

  let(:veteran_file_number) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:receipt_date) { nil }
  let(:benefit_type) { nil }
  let(:legacy_opt_in_approved) { nil }
  let(:veteran_is_not_claimant) { false }

  let(:supplemental_claim) do
    SupplementalClaim.new(
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      benefit_type: benefit_type,
      legacy_opt_in_approved: legacy_opt_in_approved,
      veteran_is_not_claimant: veteran_is_not_claimant
    )
  end

  context "#special_issues" do
    let(:vacols_id) { nil }
    let(:vacols_sequence_id) { nil }
    let!(:request_issue) do
      create(:request_issue, review_request: supplemental_claim, vacols_id: vacols_id, vacols_sequence_id: vacols_sequence_id)
    end

    subject { supplemental_claim.special_issues }

    context "no special conditions" do
      it "is empty" do
        expect(subject).to eq []
      end
    end

    context "VACOLS opt-in" do
      let(:vacols_id) { "something" }
      let!(:vacols_case) { create(:case, bfkey: vacols_id, case_issues: [vacols_issue]) }
      let(:vacols_sequence_id) { 1 }
      let!(:vacols_issue) { create(:case_issue, issseq: vacols_sequence_id) }
      let!(:legacy_opt_in) do
        create(:legacy_issue_optin, request_issue: request_issue)
      end

      it "includes VACOLS opt-in" do
        expect(subject).to include(code: "VO", narrative: Constants.VACOLS_DISPOSITIONS_BY_ID.O)
      end
    end
  end

  context "#valid?" do
    subject { supplemental_claim.valid? }

    context "when saving review" do
      before { supplemental_claim.start_review! }

      context "review fields when they are set" do
        let(:benefit_type) { "compensation" }
        let(:legacy_opt_in_approved) { false }
        let(:receipt_date) { 1.day.ago }

        it "is valid" do
          is_expected.to be true
        end
      end

      context "when they are nil" do
        let(:veteran_is_not_claimant) { nil }
        it "adds errors" do
          is_expected.to be false
          expect(supplemental_claim.errors[:benefit_type]).to include("blank")
          expect(supplemental_claim.errors[:legacy_opt_in_approved]).to include("blank")
          expect(supplemental_claim.errors[:receipt_date]).to include("blank")
          expect(supplemental_claim.errors[:veteran_is_not_claimant]).to include("blank")
        end
      end
    end

    context "receipt_date" do
      let(:benefit_type) { "compensation" }
      let(:legacy_opt_in_approved) { false }
      context "when it is nil" do
        it { is_expected.to be true }
      end

      context "when it is after today" do
        let(:receipt_date) { 1.day.from_now }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(supplemental_claim.errors[:receipt_date]).to include("in_future")
        end
      end

      context "when it is before AMA begin date" do
        let(:receipt_date) { DecisionReview.ama_activation_date - 1 }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(supplemental_claim.errors[:receipt_date]).to include("before_ama")
        end
      end

      context "when saving receipt" do
        before { supplemental_claim.start_review! }

        context "when it is nil" do
          let(:receipt_date) { nil }

          it "adds error to receipt_date" do
            is_expected.to be false
            expect(supplemental_claim.errors[:receipt_date]).to include("blank")
          end
        end
      end
    end
  end
end
