require "rails_helper"

describe RequestIssue do
  let(:rating_reference_id) { "abc123" }
  let(:contention_reference_id) { 1234 }
  let(:higher_level_review_reference_id) { "hlr123" }
  let(:review) { create(:higher_level_review, veteran_file_number: veteran.file_number) }
  let!(:veteran) { Generators::Veteran.build(file_number: "789987789") }

  let!(:rated_issue) do
    RequestIssue.create(
      review_request: review,
      rating_issue_reference_id: rating_reference_id,
      rating_issue_profile_date: Time.zone.now,
      description: "a rated issue"
    )
  end

  let!(:non_rated_issue) do
    RequestIssue.create(
      review_request: review,
      description: "a non-rated issue description",
      issue_category: "a category",
      decision_date: 1.day.ago
    )
  end

  let!(:unidentified_issue) do
    RequestIssue.create(
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
        { reference_id: "xyz456", decision_text: "PTSD denied" },
      ]
    )
  end

  context "finds issues" do
    it "filters by rated issues" do
      rated_issues = RequestIssue.rated
      expect(rated_issues.length).to eq(2)
      expect(rated_issues.find_by(id: rated_issue.id)).to_not be_nil
      expect(rated_issues.find_by(id: unidentified_issue.id)).to_not be_nil
    end

    it "filters by nonrated issues" do
      non_rated_issues = RequestIssue.nonrated
      expect(non_rated_issues.length).to eq(1)
      expect(non_rated_issues.find_by(id: non_rated_issue.id)).to_not be_nil
    end

    it "filters by unidentified issues" do
      unidentified_issues = RequestIssue.unidentified
      expect(unidentified_issues.length).to eq(1)
      expect(unidentified_issues.find_by(id: unidentified_issue.id)).to_not be_nil
    end

    context ".find_active_by_reference_id" do
      let(:active_rated_issue) do
        rated_issue.tap { |ri| ri.update!(end_product_establishment: create(:end_product_establishment, :active)) }
      end

      context "EPE is active" do
        let(:rating_issue) { RatingIssue.new(reference_id: active_rated_issue.rating_issue_reference_id) }

        it "filters by reference_id" do
          request_issue_in_review = RequestIssue.find_active_by_reference_id(rating_issue.reference_id)
          expect(request_issue_in_review).to eq(rated_issue)
        end

        it "ignores request issues that are already ineligible" do
          create(
            :request_issue,
            rating_issue_reference_id: rated_issue.rating_issue_reference_id,
            ineligible_reason: :duplicate_of_issue_in_active_review
          )

          request_issue_in_review = RequestIssue.find_active_by_reference_id(rating_issue.reference_id)
          expect(request_issue_in_review).to eq(rated_issue)
        end
      end

      context "EPE is not active" do
        let(:rating_issue) { RatingIssue.new(reference_id: rated_issue.rating_issue_reference_id) }

        it "ignores request issues" do
          expect(RequestIssue.find_active_by_reference_id(rating_issue.reference_id)).to be_nil
        end
      end
    end
  end

  context "#contention_text" do
    it "changes based on is_unidentified" do
      expect(unidentified_issue.contention_text).to eq(RequestIssue::UNIDENTIFIED_ISSUE_MSG)
      expect(rated_issue.contention_text).to eq("a rated issue")
      expect(non_rated_issue.contention_text).to eq("a category - a non-rated issue description")
    end
  end

  context "#review_title" do
    it "munges the review_request_type appropriately" do
      expect(rated_issue.review_title).to eq "Higher-Level Review"
    end
  end

  context "#contested_rating_issue" do
    it "returns the rating issue hash that prompted the RequestIssue" do
      expect(rated_issue.contested_rating_issue[:reference_id]).to eq rating_reference_id
      expect(rated_issue.contested_rating_issue[:decision_text]).to eq "Left knee granted"
    end
  end

  context "#previous_request_issue" do
    let(:prior_higher_level_review) { create(:higher_level_review) }
    let!(:prior_request_issue) do
      create(
        :request_issue,
        review_request: prior_higher_level_review,
        rating_issue_reference_id: higher_level_review_reference_id,
        contention_reference_id: contention_reference_id
      )
    end

    it "looks up the chain to the immediately previous request issue" do
      ratings.issues.select(&:contention_reference_id).each(&:save_with_request_issue!)
      binding.pry
      expect(rated_issue.previous_request_issue).to eq(prior_request_issue)
    end
  end

  context "#validate_eligibility!" do
    let(:duplicate_reference_id) { "xyz789" }
    let(:old_reference_id) { "old123" }
    let(:active_epe) { create(:end_product_establishment, :active) }
    let(:receipt_date) { review.receipt_date }

    let(:prior_higher_level_review) { create(:higher_level_review) }
    let!(:prior_request_issue) do
      create(
        :request_issue,
        review_request: prior_higher_level_review,
        rating_issue_reference_id: higher_level_review_reference_id,
        contention_reference_id: contention_reference_id
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
    end

    let!(:request_issue_in_progress) do
      create(
        :request_issue,
        end_product_establishment: active_epe,
        rating_issue_reference_id: duplicate_reference_id,
        description: "Old injury"
      )
    end

    it "flags non-rated issue as untimely when decision date is older than receipt_date" do
      non_rated_issue.decision_date = receipt_date - 400
      non_rated_issue.validate_eligibility!

      expect(non_rated_issue.untimely?).to eq(true)
    end

    it "flags rated issue as untimely when promulgation_date is year+ older than receipt_date" do
      rated_issue.rating_issue_reference_id = old_reference_id
      rated_issue.validate_eligibility!

      expect(rated_issue.untimely?).to eq(true)
    end

    it "flags duplicate rated issue as in progress" do
      rated_issue.rating_issue_reference_id = duplicate_reference_id
      rated_issue.validate_eligibility!

      expect(rated_issue.duplicate_of_issue_in_active_review?).to eq(true)
    end

    it "flags prior HLR" do
      rated_issue.rating_issue_reference_id = higher_level_review_reference_id
      rated_issue.validate_eligibility!

      expect(rated_issue.prior_higher_level_review?).to eq(true)
      expect(rated_issue.ineligible_request_issue_id).to eq(prior_request_issue.id)
    end
  end
end
