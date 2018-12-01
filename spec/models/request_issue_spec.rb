require "rails_helper"

describe RequestIssue do
  let(:rating_reference_id) { "abc123" }
  let(:contention_reference_id) { 1234 }
  let(:profile_date) { Time.zone.now }
  let(:ramp_claim_id) { nil }
  let(:higher_level_review_reference_id) { "hlr123" }
  let(:legacy_opt_in_approved) { false }
  let(:review) { create(:higher_level_review, veteran_file_number: veteran.file_number, legacy_opt_in_approved: legacy_opt_in_approved) }
  let!(:veteran) { Generators::Veteran.build(file_number: "789987789") }

  let!(:rating_request_issue) do
    create(
      :request_issue,
      review_request: review,
      rating_issue_reference_id: rating_reference_id,
      rating_issue_profile_date: profile_date,
      description: "a rating request issue",
      ramp_claim_id: ramp_claim_id
    )
  end

  let!(:nonrating_request_issue) do
    create(
      :request_issue,
      review_request: review,
      description: "a nonrating request issue description",
      issue_category: "a category",
      decision_date: 1.day.ago
    )
  end

  let!(:unidentified_issue) do
    create(
      :request_issue,
      review_request: review,
      description: "an unidentified issue",
      is_unidentified: true
    )
  end

  let!(:ratings) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: review.receipt_date - 40.days,
      profile_date: review.receipt_date - 50.days,
      issues: [
        {
          reference_id: rating_reference_id,
          decision_text: "Left knee granted",
          contention_reference_id: contention_reference_id
        },
        { reference_id: "xyz456", decision_text: "PTSD denied" }
      ]
    )
  end

  context "finds issues" do
    it "filters by rating issues" do
      rating_request_issues = RequestIssue.rating
      expect(rating_request_issues.length).to eq(2)
      expect(rating_request_issues.find_by(id: rating_request_issue.id)).to_not be_nil
      expect(rating_request_issues.find_by(id: unidentified_issue.id)).to_not be_nil
    end

    it "filters by nonrating issues" do
      nonrating_request_issues = RequestIssue.nonrating
      expect(nonrating_request_issues.length).to eq(1)
      expect(nonrating_request_issues.find_by(id: nonrating_request_issue.id)).to_not be_nil
    end

    it "filters by unidentified issues" do
      unidentified_issues = RequestIssue.unidentified
      expect(unidentified_issues.length).to eq(1)
      expect(unidentified_issues.find_by(id: unidentified_issue.id)).to_not be_nil
    end

    context ".find_active_by_reference_id" do
      let(:active_rating_request_issue) do
        rating_request_issue.tap do |ri|
          ri.update!(end_product_establishment: create(:end_product_establishment, :active))
        end
      end

      context "EPE is active" do
        let(:rating_issue) { RatingIssue.new(reference_id: active_rating_request_issue.rating_issue_reference_id) }

        it "filters by reference_id" do
          request_issue_in_review = RequestIssue.find_active_by_reference_id(rating_issue.reference_id)
          expect(request_issue_in_review).to eq(rating_request_issue)
        end

        it "ignores request issues that are already ineligible" do
          create(
            :request_issue,
            rating_issue_reference_id: rating_request_issue.rating_issue_reference_id,
            ineligible_reason: :duplicate_of_issue_in_active_review
          )

          request_issue_in_review = RequestIssue.find_active_by_reference_id(rating_issue.reference_id)
          expect(request_issue_in_review).to eq(rating_request_issue)
        end
      end

      context "EPE is not active" do
        let(:rating_issue) { RatingIssue.new(reference_id: rating_request_issue.rating_issue_reference_id) }

        it "ignores request issues" do
          expect(RequestIssue.find_active_by_reference_id(rating_issue.reference_id)).to be_nil
        end
      end
    end
  end

  context "#ui_hash" do
    context "when there is a previous request issue in active review" do
      let(:previous_higher_level_review) { create(:higher_level_review, id: 10) }
      let(:new_higher_level_review) { create(:higher_level_review, id: 11) }
      let(:active_epe) { create(:end_product_establishment, :active) }

      let!(:request_issue_in_active_review) do
        create(
          :request_issue,
          review_request: previous_higher_level_review,
          rating_issue_reference_id: higher_level_review_reference_id,
          contention_reference_id: contention_reference_id,
          end_product_establishment: active_epe,
          removed_at: nil,
          ineligible_reason: nil
        )
      end

      let!(:ineligible_request_issue) do
        create(
          :request_issue,
          review_request: new_higher_level_review,
          rating_issue_reference_id: higher_level_review_reference_id,
          contention_reference_id: contention_reference_id,
          ineligible_reason: :duplicate_of_issue_in_active_review,
          ineligible_due_to: request_issue_in_active_review
        )
      end

      it "returns the review title of the request issue in active review" do
        expect(ineligible_request_issue.ui_hash).to include(
          title_of_active_review: request_issue_in_active_review.review_title
        )
      end
    end
  end

  context "#contention_text" do
    it "changes based on is_unidentified" do
      expect(unidentified_issue.contention_text).to eq(RequestIssue::UNIDENTIFIED_ISSUE_MSG)
      expect(rating_request_issue.contention_text).to eq("a rating request issue")
      expect(nonrating_request_issue.contention_text).to eq("a category - a nonrating request issue description")
    end
  end

  context "#review_title" do
    it "munges the review_request_type appropriately" do
      expect(rating_request_issue.review_title).to eq "Higher-Level Review"
    end
  end

  context "#contested_rating_issue" do
    it "returns the rating issue hash that prompted the RequestIssue" do
      expect(rating_request_issue.contested_rating_issue.reference_id).to eq rating_reference_id
      expect(rating_request_issue.contested_rating_issue.decision_text).to eq "Left knee granted"
    end
  end

  context "#previous_request_issue" do
    let(:previous_higher_level_review) { create(:higher_level_review, receipt_date: review.receipt_date - 100.days) }
    let(:previous_end_product_establishment) do
      create(
        :end_product_establishment,
        :cleared,
        veteran_file_number: veteran.file_number,
        established_at: previous_higher_level_review.receipt_date + 1.day
      )
    end
    let!(:previous_request_issue) do
      create(
        :request_issue,
        review_request: previous_higher_level_review,
        rating_issue_reference_id: higher_level_review_reference_id,
        contention_reference_id: contention_reference_id,
        end_product_establishment: previous_end_product_establishment
      )
    end

    it "looks up the chain to the immediately previous request issue" do
      previous_end_product_establishment.sync_decision_issues!
      expect(rating_request_issue.previous_request_issue).to eq(previous_request_issue)
    end

    it "returns nil if decision issues have not yet been synced" do
      expect(rating_request_issue.previous_request_issue).to be_nil
    end
  end

  context "#valid?" do
    subject { request_issue.valid? }
    let(:request_issue) do
      build(:request_issue, untimely_exemption: untimely_exemption, ineligible_reason: ineligible_reason)
    end

    context "untimely exemption is true" do
      let(:untimely_exemption) { true }
      let(:ineligible_reason) { :untimely }
      it "validates that the ineligible_reason can't be untimely" do
        expect(subject).to be_falsey
      end
    end
  end

  context "#validate_eligibility!" do
    let(:duplicate_reference_id) { "xyz789" }
    let(:duplicate_appeal_reference_id) { "xyz555" }
    let(:old_reference_id) { "old123" }
    let(:active_epe) { create(:end_product_establishment, :active) }
    let(:receipt_date) { review.receipt_date }

    let(:previous_higher_level_review) { create(:higher_level_review) }
    let!(:previous_request_issue) do
      create(
        :request_issue,
        review_request: previous_higher_level_review,
        rating_issue_reference_id: higher_level_review_reference_id,
        contention_reference_id: contention_reference_id
      )
    end
    let(:appeal_in_progress) do
      create(:appeal, veteran_file_number: veteran.file_number).tap(&:create_tasks_on_intake_success!)
    end
    let(:appeal_request_issue_in_progress) do
      create(
        :request_issue,
        review_request: appeal_in_progress,
        rating_issue_reference_id: duplicate_appeal_reference_id,
        description: "Appealed injury"
      )
    end

    let!(:ratings) do
      Generators::Rating.build(
        participant_id: veteran.participant_id,
        promulgation_date: receipt_date - 40.days,
        profile_date: receipt_date - 50.days,
        issues: [
          { reference_id: "xyz123", decision_text: "Left knee granted" },
          { reference_id: "xyz456", decision_text: "PTSD denied" },
          { reference_id: duplicate_reference_id, decision_text: "Old injury" },
          { reference_id: duplicate_appeal_reference_id, decision_text: "Appealed injury" },
          {
            reference_id: higher_level_review_reference_id,
            decision_text: "Already reviewed injury",
            contention_reference_id: contention_reference_id
          }
        ]
      )
      Generators::Rating.build(
        participant_id: veteran.participant_id,
        promulgation_date: receipt_date - 400.days,
        profile_date: receipt_date - 450.days,
        issues: [
          { reference_id: old_reference_id, decision_text: "Really old injury" }
        ]
      )
      Generators::Rating.build(
        participant_id: veteran.participant_id,
        promulgation_date: DecisionReview.ama_activation_date - 5.days,
        profile_date: DecisionReview.ama_activation_date - 10.days,
        issues: [
          { reference_id: "before_ama_ref_id", decision_text: "Non-RAMP Issue before AMA Activation" },
          { decision_text: "Issue before AMA Activation from RAMP",
            associated_claims: { bnft_clm_tc: "683SCRRRAMP", clm_id: "ramp_claim_id" },
            reference_id: "ramp_ref_id" }
        ]
      )
    end

    let!(:request_issue_in_progress) do
      create(
        :request_issue,
        end_product_establishment: active_epe,
        rating_issue_reference_id: duplicate_reference_id,
        description: "Old injury"
      )
    end

    it "flags nonrating request issue as untimely when decision date is older than receipt_date" do
      nonrating_request_issue.decision_date = receipt_date - 400
      nonrating_request_issue.validate_eligibility!

      expect(nonrating_request_issue.untimely?).to eq(true)
    end

    it "flags rating request issue as untimely when promulgation_date is year+ older than receipt_date" do
      rating_request_issue.rating_issue_reference_id = old_reference_id
      rating_request_issue.validate_eligibility!

      expect(rating_request_issue.untimely?).to eq(true)
    end

    it "flags duplicate rating request issue as in progress" do
      rating_request_issue.rating_issue_reference_id = duplicate_reference_id
      rating_request_issue.validate_eligibility!

      expect(rating_request_issue.duplicate_of_issue_in_active_review?).to eq(true)
      expect(rating_request_issue.ineligible_due_to).to eq(request_issue_in_progress)

      rating_request_issue.save!
      expect(request_issue_in_progress.duplicate_but_ineligible).to eq([rating_request_issue])
    end

    it "flags duplicate appeal as in progress" do
      rating_request_issue.rating_issue_reference_id = appeal_request_issue_in_progress.rating_issue_reference_id
      rating_request_issue.validate_eligibility!

      expect(rating_request_issue.duplicate_of_issue_in_active_review?).to eq(true)
    end

    it "flags previous HLR" do
      rating_request_issue.rating_issue_reference_id = higher_level_review_reference_id
      rating_request_issue.validate_eligibility!

      expect(rating_request_issue.previous_higher_level_review?).to eq(true)
      expect(rating_request_issue.ineligible_due_to).to eq(previous_request_issue)

      rating_request_issue.save!
      expect(previous_request_issue.duplicate_but_ineligible).to eq([rating_request_issue])
    end

    context "Issues with legacy issues" do
      before do
        FeatureToggle.enable!(:intake_legacy_opt_in)

        # Active and eligible
        create(:legacy_appeal, vacols_case:
          create(:case, :status_active, bfkey: "vacols1", bfcorlid: "#{veteran.file_number}S", bfdnod: 3.days.ago, bfdsoc: 3.days.ago))
        allow(AppealRepository).to receive(:issues).with("vacols1")
          .and_return([
                        Generators::Issue.build(id: "vacols1", vacols_sequence_id: 1, codes: %w[02 15 03 5250]),
                        Generators::Issue.build(id: "vacols1", vacols_sequence_id: 2, codes: %w[02 15 03 5251])
                      ])

        # Active and not eligible
        create(:legacy_appeal, vacols_case:
          create(:case, :status_active, bfkey: "vacols2", bfcorlid: "#{veteran.file_number}S", bfdnod: 4.years.ago, bfdsoc: 4.months.ago))
        allow(AppealRepository).to receive(:issues).with("vacols2")
          .and_return([
                        Generators::Issue.build(id: "vacols2", vacols_sequence_id: 1, codes: %w[02 15 03 5243]),
                        Generators::Issue.build(id: "vacols2", vacols_sequence_id: 2, codes: %w[02 15 03 5242])
                      ])
      end

      after do
        FeatureToggle.disable!(:intake_legacy_opt_in)
      end

      context "when legacy opt in is not approved" do
        let(:legacy_opt_in_approved) { false }
        it "flags issues with connected issues if legacy opt in is not approved" do
          nonrating_request_issue.vacols_id = "vacols1"
          nonrating_request_issue.vacols_sequence_id = "1"
          nonrating_request_issue.validate_eligibility!

          expect(nonrating_request_issue.ineligible_reason).to eq("legacy_issue_not_withdrawn")

          rating_request_issue.vacols_id = "vacols1"
          rating_request_issue.vacols_sequence_id = "2"
          rating_request_issue.validate_eligibility!

          expect(rating_request_issue.ineligible_reason).to eq("legacy_issue_not_withdrawn")
        end
      end

      context "when legacy opt in is approved" do
        let(:legacy_opt_in_approved) { true }
        it "flags issues connected to ineligible appeals if legacy opt in is approved" do
          nonrating_request_issue.vacols_id = "vacols2"
          nonrating_request_issue.vacols_sequence_id = "1"
          nonrating_request_issue.validate_eligibility!

          expect(nonrating_request_issue.ineligible_reason).to eq("legacy_appeal_not_eligible")

          rating_request_issue.vacols_id = "vacols2"
          rating_request_issue.vacols_sequence_id = "2"
          rating_request_issue.validate_eligibility!

          expect(rating_request_issue.ineligible_reason).to eq("legacy_appeal_not_eligible")
        end
      end
    end

    context "Issues with decision dates before AMA" do
      let(:profile_date) { DecisionReview.ama_activation_date - 5.days }

      it "flags nonrating issues before AMA" do
        nonrating_request_issue.decision_date = DecisionReview.ama_activation_date - 5.days
        nonrating_request_issue.validate_eligibility!

        expect(nonrating_request_issue.ineligible_reason).to eq("before_ama")
      end

      it "flags rating issues before AMA" do
        rating_request_issue.rating_issue_reference_id = "before_ama_ref_id"
        rating_request_issue.validate_eligibility!
        expect(rating_request_issue.ineligible_reason).to eq("before_ama")
      end

      context "rating issue is from a RAMP decision" do
        let(:ramp_claim_id) { "ramp_claim_id" }

        it "does not flag rating issues before AMA from a RAMP decision" do
          rating_request_issue.rating_issue_reference_id = "ramp_ref_id"
          rating_request_issue.validate_eligibility!
          expect(rating_request_issue.ineligible_reason).to be_nil
        end
      end
    end
  end
end
