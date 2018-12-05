describe HigherLevelReview do
  before do
    FeatureToggle.enable!(:intake_legacy_opt_in)
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:intake_legacy_opt_in)
  end

  let(:veteran_file_number) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: veteran_file_number) }
  let(:receipt_date) { DecisionReview.ama_activation_date + 1 }
  let(:benefit_type) { "compensation" }
  let(:informal_conference) { nil }
  let(:same_office) { nil }
  let(:legacy_opt_in_approved) { false }
  let(:veteran_is_not_claimant) { false }

  let(:higher_level_review) do
    HigherLevelReview.new(
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      informal_conference: informal_conference,
      same_office: same_office,
      benefit_type: benefit_type,
      legacy_opt_in_approved: legacy_opt_in_approved,
      veteran_is_not_claimant: veteran_is_not_claimant
    )
  end

  context "#special_issues" do
    let(:vacols_id) { nil }
    let!(:request_issue) do
      create(:request_issue, review_request: higher_level_review, vacols_id: vacols_id)
    end

    subject { higher_level_review.special_issues }

    context "no special conditions" do
      it "is empty" do
        expect(subject).to eq []
      end
    end

    context "VACOLS opt-in" do
      let(:vacols_id) { "something" }

      it "includes VACOLS opt-in" do
        expect(subject).to include(code: "VO", narrative: "VACOLS Opt-in")
      end
    end

    context "same office" do
      let(:same_office) { true }

      it "includes same office" do
        expect(subject).to include(code: "SSR", narrative: "Same Station Review")
      end
    end
  end

  context "#valid?" do
    subject { higher_level_review.valid? }

    context "receipt_date" do
      context "when it is nil" do
        let(:receipt_date) { nil }
        it { is_expected.to be true }
      end

      context "when it is after today" do
        let(:receipt_date) { 1.day.from_now }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(higher_level_review.errors[:receipt_date]).to include("in_future")
        end
      end

      context "when it is before AMA begin date" do
        let(:receipt_date) { DecisionReview.ama_activation_date - 1 }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(higher_level_review.errors[:receipt_date]).to include("before_ama")
        end
      end

      context "when saving receipt" do
        before { higher_level_review.start_review! }

        context "when it is nil" do
          let(:receipt_date) { nil }

          it "adds error to receipt_date" do
            is_expected.to be false
            expect(higher_level_review.errors[:receipt_date]).to include("blank")
          end
        end
      end
    end

    context "informal_conference, same_office, legacy opt-in, veteran_is_not_claimant" do
      context "when saving review" do
        before { higher_level_review.start_review! }

        context "when they are set" do
          let(:informal_conference) { true }
          let(:same_office) { false }
          let(:legacy_opt_in_approved) { false }

          it "is valid" do
            is_expected.to be true
          end
        end

        context "when they are nil" do
          let(:legacy_opt_in_approved) { nil }
          let(:veteran_is_not_claimant) { nil }
          it "adds errors to informal_conference and same_office" do
            is_expected.to be false
            expect(higher_level_review.errors[:informal_conference]).to include("blank")
            expect(higher_level_review.errors[:same_office]).to include("blank")
            expect(higher_level_review.errors[:legacy_opt_in_approved]).to include("blank")
            expect(higher_level_review.errors[:veteran_is_not_claimant]).to include("blank")
          end
        end
      end
    end
  end

  context "#claimant_participant_id" do
    subject { higher_level_review.claimant_participant_id }

    it "returns claimant's participant ID" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "00")
      higher_level_review.save!
      expect(subject).to eql("12345")
    end

    it "returns new claimant's participant ID if replaced" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "00")
      higher_level_review.create_claimants!(participant_id: "23456", payee_code: "00")
      higher_level_review.reload
      expect(subject).to eql("23456")
    end

    it "returns nil when there are no claimants" do
      expect(subject).to be_nil
    end
  end

  context "#payee_code" do
    subject { higher_level_review.payee_code }

    it "returns claimant's payee_code" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "10")
      higher_level_review.save!
      expect(subject).to eql("10")
    end

    it "returns new claimant's payee_code if replaced" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "10")
      higher_level_review.create_claimants!(participant_id: "23456", payee_code: "11")
      higher_level_review.reload
      expect(subject).to eql("11")
    end

    it "returns nil when there are no claimants" do
      expect(subject).to be_nil
    end
  end

  context "#claimant_not_veteran" do
    subject { higher_level_review.claimant_not_veteran }

    it "returns true if claimant is not veteran" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "10")
      expect(subject).to be true
    end

    it "returns false if claimant is veteran" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: veteran.participant_id, payee_code: "00")
      expect(subject).to be false
    end

    it "returns nil if there are no claimants" do
      expect(subject).to be_nil
    end
  end

  context "#on_decision_issues_sync_processed" do
    subject { higher_level_review.on_decision_issues_sync_processed(end_product_establishment) }

    let(:end_product_establishment) do
      create(:end_product_establishment,
             source: higher_level_review)
    end

    context "when there are dta errors" do
      let!(:decision_issues) do
        [
          create(:decision_issue,
                 decision_review: higher_level_review,
                 disposition: HigherLevelReview::DTA_ERROR_PMR,
                 rating_issue_reference_id: "rating1"),
          create(:decision_issue,
                 decision_review: higher_level_review,
                 disposition: HigherLevelReview::DTA_ERROR_FED_RECS,
                 rating_issue_reference_id: "rating2"),
          create(:decision_issue,
                 decision_review: higher_level_review,
                 disposition: "not a dta error")
        ]
      end

      let!(:claimant) do
        Claimant.create!(
          review_request: higher_level_review,
          participant_id: veteran.participant_id,
          payee_code: "10"
        )
      end

      it "creates a supplemental claim and request issues" do
        subject
        supplemental_claim = SupplementalClaim.find_by(
          is_dta_error: true,
          veteran_file_number: higher_level_review.veteran_file_number,
          receipt_date: Time.zone.now.to_date,
          benefit_type: higher_level_review.benefit_type,
          legacy_opt_in_approved: higher_level_review.legacy_opt_in_approved,
          veteran_is_not_claimant: higher_level_review.veteran_is_not_claimant
        )

        expect(supplemental_claim).to_not be_nil
        expect(RequestIssue.where(review_request: supplemental_claim).length).to eq(2)

        first_dta_request_issue = RequestIssue.find_by(
          review_request: supplemental_claim,
          contested_decision_issue_id: decision_issues.first.id,
          rating_issue_reference_id: "rating1",
          rating_issue_profile_date: decision_issues.first.profile_date,
          issue_category: decision_issues.first.issue_category,
          benefit_type: higher_level_review.benefit_type,
          decision_date: decision_issues.first.approx_decision_date
        )

        expect(first_dta_request_issue).to_not be_nil

        second_dta_request_issue = RequestIssue.find_by(
          review_request: supplemental_claim,
          contested_decision_issue_id: decision_issues.second.id,
          rating_issue_reference_id: "rating2",
          rating_issue_profile_date: decision_issues.second.profile_date,
          issue_category: decision_issues.second.issue_category,
          benefit_type: higher_level_review.benefit_type,
          decision_date: decision_issues.second.approx_decision_date
        )

        expect(second_dta_request_issue).to_not be_nil
      end
    end

    context "when there are no dta errors" do
      it "does nothing" do
        subject

        expect(SupplementalClaim.where(is_dta_error: true).empty?).to eq(true)
        expect(RequestIssue.all.empty?).to eq(true)
      end
    end
  end
end
