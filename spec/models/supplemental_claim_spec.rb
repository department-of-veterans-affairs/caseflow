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
  let(:decision_review_remanded) { nil }

  let(:supplemental_claim) do
    SupplementalClaim.new(
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      benefit_type: benefit_type,
      legacy_opt_in_approved: legacy_opt_in_approved,
      veteran_is_not_claimant: veteran_is_not_claimant,
      decision_review_remanded: decision_review_remanded
    )
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

  context "create_remand_issues!" do
    subject { supplemental_claim.create_remand_issues! }

    let(:decision_review_remanded) { create(:appeal) }
    let!(:decision_document) do
      create(:decision_document, decision_date: Time.zone.today - 3.days, appeal: decision_review_remanded)
    end
    let(:benefit_type) { "education" }

    let!(:decision_issue_not_remanded) do
      create(
        :decision_issue,
        disposition: "allowed",
        benefit_type: benefit_type,
        decision_review: decision_review_remanded
      )
    end

    let!(:decision_issue_benefit_type_not_matching) do
      create(
        :decision_issue,
        disposition: "remanded",
        benefit_type: "insurance",
        decision_review: decision_review_remanded
      )
    end

    let!(:decision_issue_needing_remand) do
      create(
        :decision_issue,
        disposition: "remanded",
        benefit_type: benefit_type,
        decision_review: decision_review_remanded,
        rating_issue_reference_id: "1234",
        description: "a description"
      )
    end

    it "creates remand issues for appropriate decision issues" do
      expect { subject }.to change(supplemental_claim.request_issues, :count).by(1)

      expect(supplemental_claim.request_issues.last).to have_attributes(
        contested_decision_issue_id: decision_issue_needing_remand.id,
        contested_rating_issue_reference_id: decision_issue_needing_remand.rating_issue_reference_id,
        contested_rating_issue_profile_date: decision_issue_needing_remand.profile_date,
        contested_issue_description: decision_issue_needing_remand.description,
        benefit_type: benefit_type
      )
    end

    it "doesn't create duplicate remand issues" do
      supplemental_claim.create_remand_issues!

      expect { subject }.to_not change(supplemental_claim.request_issues, :count)
    end
  end

  context "#issues" do
    let(:receipt_date) { Time.new("2018", "03", "01").utc }
    let(:benefit_type) { "compensation" }

    let!(:sc) do
      create(:supplemental_claim,
             veteran_file_number: veteran_file_number,
             receipt_date: receipt_date,
             benefit_type: benefit_type)
    end

    let(:ep_status) { "PEND" }
    let!(:sc_ep) do
      create(:end_product_establishment,
             synced_status: ep_status, source: sc, last_synced_at: receipt_date + 100.days)
    end
    let!(:request_issue) do
      create(:request_issue,
             review_request: sc,
             benefit_type: benefit_type,
             contested_rating_issue_diagnostic_code: nil)
    end

    context "claim is open, pending a decision" do
      it "status gives status info of the request issue" do
        issue_statuses = sc.issues_hash

        expect(issue_statuses.empty?).to eq(false)
        expect(issue_statuses.first[:active]).to eq(true)
        expect(issue_statuses.first[:last_action]).to be_nil
        expect(issue_statuses.first[:date]).to be_nil
        expect(issue_statuses.first[:description]).to eq("Compensation issue")
        expect(issue_statuses.first[:diagnosticCode]).to be_nil
      end
    end

    context "claim has a decision" do
      let(:ep_status) { "CLR" }
      let!(:decision_issue) do
        create(:decision_issue,
               decision_review: sc, end_product_last_action_date: receipt_date + 100.days,
               benefit_type: benefit_type, diagnostic_code: nil)
      end

      it "status gives status info of the decision issue" do
        issue_statuses = sc.issues_hash
        expect(issue_statuses.empty?).to eq(false)
        expect(issue_statuses.first[:active]).to eq(false)
        expect(issue_statuses.first[:last_action]).to eq("allowed")
        expect(issue_statuses.first[:date]).to eq(receipt_date + 100.days)
        expect(issue_statuses.first[:description]).to eq("Compensation issue")
        expect(issue_statuses.first[:diagnosticCode]).to be_nil
      end
    end
  end
end
