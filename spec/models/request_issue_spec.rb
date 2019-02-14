describe RequestIssue do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  let(:contested_rating_issue_reference_id) { "abc123" }
  let(:profile_date) { Time.zone.now.to_s }
  let(:contention_reference_id) { "1234" }
  let(:ramp_claim_id) { nil }
  let(:higher_level_review_reference_id) { "hlr123" }
  let(:legacy_opt_in_approved) { false }
  let(:contested_decision_issue_id) { nil }
  let(:benefit_type) { "compensation" }
  let(:same_office) { false }
  let(:vacols_id) { nil }
  let(:vacols_sequence_id) { nil }
  let(:closed_at) { nil }
  let(:closed_status) { nil }

  let(:review) do
    create(
      :higher_level_review,
      veteran_file_number: veteran.file_number,
      legacy_opt_in_approved: legacy_opt_in_approved,
      same_office: same_office
    )
  end

  let(:rating_promulgation_date) { (review.receipt_date - 40.days).in_time_zone }

  let!(:ratings) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: rating_promulgation_date,
      profile_date: (review.receipt_date - 50.days).in_time_zone,
      issues: issues,
      associated_claims: associated_claims
    )
  end

  let!(:veteran) { Generators::Veteran.build(file_number: "789987789") }
  let!(:decision_sync_processed_at) { nil }
  let!(:end_product_establishment) { nil }
  let(:issues) do
    [
      {
        reference_id: contested_rating_issue_reference_id,
        decision_text: "Left knee granted",
        contention_reference_id: contention_reference_id
      },
      { reference_id: "xyz456", decision_text: "PTSD denied" }
    ]
  end

  let!(:rating_request_issue) do
    create(
      :request_issue,
      review_request: review,
      contested_rating_issue_reference_id: contested_rating_issue_reference_id,
      contested_rating_issue_profile_date: profile_date,
      contested_issue_description: "a rating request issue",
      ramp_claim_id: ramp_claim_id,
      decision_sync_processed_at: decision_sync_processed_at,
      end_product_establishment: end_product_establishment,
      contention_reference_id: contention_reference_id,
      contested_decision_issue_id: contested_decision_issue_id,
      benefit_type: benefit_type,
      vacols_id: vacols_id,
      vacols_sequence_id: vacols_sequence_id,
      closed_at: closed_at,
      closed_status: closed_status
    )
  end

  let!(:nonrating_request_issue) do
    create(
      :request_issue,
      review_request: review,
      nonrating_issue_description: "a nonrating request issue description",
      contested_issue_description: nonrating_contested_issue_description,
      issue_category: "a category",
      decision_date: 1.day.ago,
      decision_sync_processed_at: decision_sync_processed_at,
      end_product_establishment: end_product_establishment,
      contention_reference_id: contention_reference_id,
      benefit_type: benefit_type
    )
  end

  let(:nonrating_contested_issue_description) { nil }

  let!(:unidentified_issue) do
    create(
      :request_issue,
      review_request: review,
      unidentified_issue_text: "an unidentified issue",
      is_unidentified: true
    )
  end

  let(:associated_claims) { [] }

  context ".requires_processing" do
    before do
      rating_request_issue.submit_for_processing!(delay: 1.day)
      nonrating_request_issue.submit_for_processing!
    end

    it "respects the delay" do
      expect(rating_request_issue.submitted_and_ready?).to eq(false)
      expect(rating_request_issue.submitted?).to eq(true)
      expect(nonrating_request_issue.submitted?).to eq(true)

      todo = RequestIssue.requires_processing
      expect(todo).to_not include(rating_request_issue)
      expect(todo).to include(nonrating_request_issue)
    end
  end

  context ".rating" do
    subject { RequestIssue.rating }

    it "filters by rating issues" do
      expect(subject.length).to eq(2)

      expect(subject.find_by(id: rating_request_issue.id)).to_not be_nil
      expect(subject.find_by(id: unidentified_issue.id)).to_not be_nil
    end
  end

  context ".nonrating" do
    subject { RequestIssue.nonrating }

    it "filters by nonrating issues" do
      expect(subject.length).to eq(1)
      expect(subject.find_by(id: nonrating_request_issue.id)).to_not be_nil
    end
  end

  context ".unidentified" do
    subject { RequestIssue.unidentified }

    it "filters by unidentified issues" do
      expect(subject.length).to eq(1)
      expect(subject.find_by(id: unidentified_issue.id)).to_not be_nil
    end
  end

  context ".not_deleted" do
    subject { RequestIssue.not_deleted }

    let!(:deleted_request_issue) { create(:request_issue, review_request: nil) }

    it "filters by whether it is associated with a review_request" do
      expect(subject.find_by(id: deleted_request_issue.id)).to be_nil
    end
  end

  context ".open" do
    subject { RequestIssue.open }

    let!(:closed_request_issue) { create(:request_issue, :removed) }

    it "filters by whether the closed_at is nil" do
      expect(subject.find_by(id: closed_request_issue.id)).to be_nil
    end
  end

  context ".find_active_by_contested_rating_issue_reference_id" do
    let(:active_rating_request_issue) do
      rating_request_issue.tap do |ri|
        ri.update!(end_product_establishment: create(:end_product_establishment, :active))
      end
    end

    context "EPE is active" do
      let(:rating_issue) do
        RatingIssue.new(reference_id: active_rating_request_issue.contested_rating_issue_reference_id)
      end

      it "filters by reference_id" do
        in_review = RequestIssue.find_active_by_contested_rating_issue_reference_id(rating_issue.reference_id)
        expect(in_review).to eq(rating_request_issue)
      end

      it "ignores request issues that are already ineligible" do
        create(
          :request_issue,
          contested_rating_issue_reference_id: rating_request_issue.contested_rating_issue_reference_id,
          ineligible_reason: :duplicate_of_rating_issue_in_active_review
        )

        in_review = RequestIssue.find_active_by_contested_rating_issue_reference_id(rating_issue.reference_id)
        expect(in_review).to eq(rating_request_issue)
      end
    end

    context "EPE is not active" do
      let(:rating_issue) { RatingIssue.new(reference_id: rating_request_issue.contested_rating_issue_reference_id) }

      it "ignores request issues" do
        expect(RequestIssue.find_active_by_contested_rating_issue_reference_id(rating_issue.reference_id)).to be_nil
      end
    end

    context "EPE does not yet have a synced status" do
      let(:active_rating_request_issue) do
        rating_request_issue.tap do |ri|
          ri.update!(end_product_establishment: create(:end_product_establishment))
        end
      end

      let(:rating_issue) do
        RatingIssue.new(reference_id: active_rating_request_issue.contested_rating_issue_reference_id)
      end

      it "treats EPE as active" do
        in_review = RequestIssue.find_active_by_contested_rating_issue_reference_id(rating_issue.reference_id)
        expect(in_review).to eq(rating_request_issue)
      end
    end
  end

  context "#end_product_code" do
    subject { request_issue.end_product_code }

    context "when on original decision review" do
      context "when benefit type is pension" do
        let(:benefit_type) { "pension" }

        context "when decision review is a higher level review" do
          let(:review) { create(:higher_level_review) }

          context "when rating" do
            let(:request_issue) { rating_request_issue }
            it { is_expected.to eq "030HLRRPMC" }
          end

          context "when nonrating" do
            let(:request_issue) { nonrating_request_issue }
            it { is_expected.to eq "030HLRNRPMC" }
          end
        end

        context "when decision review is a supplemental claim" do
          let(:review) { create(:supplemental_claim, decision_review_remanded: nil) }

          context "when rating" do
            let(:request_issue) { rating_request_issue }
            it { is_expected.to eq "040SCRPMC" }
          end

          context "when nonrating" do
            let(:request_issue) { nonrating_request_issue }
            it { is_expected.to eq "040SCNRPMC" }
          end
        end
      end

      context "when benefit type is compensation" do
        let(:benefit_type) { "compensation" }

        context "when decision review is a higher level review" do
          let(:review) { create(:higher_level_review) }

          context "when rating" do
            let(:request_issue) { rating_request_issue }
            it { is_expected.to eq "030HLRR" }
          end

          context "when nonrating" do
            let(:request_issue) { nonrating_request_issue }
            it { is_expected.to eq "030HLRNR" }
          end
        end

        context "when decision review is a supplemental claim" do
          let(:review) { create(:supplemental_claim, decision_review_remanded: nil) }

          context "when rating" do
            let(:request_issue) { rating_request_issue }
            it { is_expected.to eq "040SCR" }
          end

          context "when nonrating" do
            let(:request_issue) { nonrating_request_issue }
            it { is_expected.to eq "040SCNR" }
          end
        end
      end
    end

    context "when on remand (dta) decision review" do
      let(:decision_review_remanded) { nil }
      let(:review) { create(:supplemental_claim, decision_review_remanded: decision_review_remanded) }

      context "when benefit type is pension" do
        let(:benefit_type) { "pension" }

        context "when decision review remanded is an Appeal" do
          let(:decision_review_remanded) { create(:appeal) }
          let(:request_issue) { rating_request_issue }

          context "when imo" do
            let(:contested_decision_issue_id) do
              create(:decision_issue, :imo, decision_review: decision_review_remanded).id
            end
            it { is_expected.to eq "040BDEIMOPMC" }
          end

          context "when not imo" do
            let(:contested_decision_issue_id) { create(:decision_issue, decision_review: decision_review_remanded).id }
            it { is_expected.to eq "040BDEPMC" }
          end
        end

        context "when decision review remanded is a claim review" do
          let(:decision_review_remanded) { create(:higher_level_review) }

          context "when rating" do
            let(:request_issue) { rating_request_issue }
            it { is_expected.to eq "040HDERPMC" }
          end

          context "when nonrating" do
            let(:request_issue) { nonrating_request_issue }
            it { is_expected.to eq "040HDENRPMC" }
          end
        end
      end

      context "when benefit type is compensation" do
        let(:benefit_type) { "compensation" }

        context "when decision review remanded is an Appeal" do
          let(:decision_review_remanded) { create(:appeal) }
          let(:request_issue) { rating_request_issue }

          context "when imo" do
            let(:contested_decision_issue_id) do
              create(:decision_issue, :imo, decision_review: decision_review_remanded).id
            end
            it { is_expected.to eq "040BDEIMO" }
          end

          context "when not imo" do
            let(:contested_decision_issue_id) { create(:decision_issue, decision_review: decision_review_remanded).id }
            it { is_expected.to eq "040BDE" }
          end
        end

        context "when decision review remanded is a claim review" do
          let(:decision_review_remanded) { create(:higher_level_review) }

          context "when rating" do
            let(:request_issue) { rating_request_issue }
            it { is_expected.to eq "040HDER" }
          end

          context "when nonrating" do
            let(:request_issue) { nonrating_request_issue }
            it { is_expected.to eq "040HDENR" }
          end
        end
      end
    end
  end

  context "#ui_hash" do
    context "when there is a previous request issue in active review" do
      let!(:ratings) do
        Generators::Rating.build(
          participant_id: veteran.participant_id,
          promulgation_date: 10.days.ago,
          profile_date: 20.days.ago,
          issues: [
            {
              reference_id: higher_level_review_reference_id,
              decision_text: "text",
              contention_reference_id: contention_reference_id
            }
          ]
        )
      end

      let(:previous_higher_level_review) do
        create(:higher_level_review, id: 10, veteran_file_number: veteran.file_number)
      end

      let(:new_higher_level_review) do
        create(:higher_level_review, id: 11, veteran_file_number: veteran.file_number)
      end

      let(:active_epe) { create(:end_product_establishment, :active) }

      let!(:request_issue_in_active_review) do
        create(
          :request_issue,
          review_request: previous_higher_level_review,
          contested_rating_issue_reference_id: higher_level_review_reference_id,
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
          contested_rating_issue_reference_id: higher_level_review_reference_id,
          contention_reference_id: contention_reference_id,
          ineligible_reason: :duplicate_of_rating_issue_in_active_review,
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

  context ".from_intake_data" do
    subject { RequestIssue.from_intake_data(data) }

    let(:data) do
      {
        rating_issue_reference_id: rating_issue_reference_id,
        decision_text: "decision text",
        issue_category: issue_category,
        is_unidentified: is_unidentified,
        decision_date: Time.zone.today,
        notes: "notes",
        untimely_exemption: true,
        untimely_exemption_notes: "untimely notes",
        ramp_claim_id: "ramp_claim_id",
        vacols_sequence_id: 2,
        contested_decision_issue_id: contested_decision_issue_id,
        ineligible_reason: "untimely",
        ineligible_due_to_id: 345,
        rating_issue_diagnostic_code: "2222"
      }
    end

    let(:rating_issue_reference_id) { nil }
    let(:contested_decision_issue_id) { nil }
    let(:issue_category) { nil }
    let(:is_unidentified) { nil }

    it do
      is_expected.to have_attributes(
        decision_date: Time.zone.today,
        notes: "notes",
        untimely_exemption: true,
        untimely_exemption_notes: "untimely notes",
        ramp_claim_id: "ramp_claim_id",
        vacols_sequence_id: 2,
        ineligible_reason: "untimely",
        ineligible_due_to_id: 345,
        contested_rating_issue_diagnostic_code: "2222"
      )
    end

    context "when rating_issue_reference_id is set" do
      let(:rating_issue_reference_id) { "refid" }

      it do
        is_expected.to have_attributes(
          contested_rating_issue_reference_id: "refid",
          contested_issue_description: "decision text",
          nonrating_issue_description: nil,
          unidentified_issue_text: nil
        )
      end
    end

    context "when contested_decision_issue_id is set" do
      let(:contested_decision_issue_id) do
        create(:decision_issue).id
      end

      it do
        is_expected.to have_attributes(
          contested_decision_issue_id: contested_decision_issue_id,
          contested_issue_description: "decision text",
          nonrating_issue_description: nil,
          unidentified_issue_text: nil
        )
      end
    end

    context "when issue_category is set" do
      let(:issue_category) { "other" }

      it do
        is_expected.to have_attributes(
          issue_category: "other",
          contested_issue_description: nil,
          nonrating_issue_description: "decision text",
          unidentified_issue_text: nil
        )
      end
    end

    context "when is_unidentified is set" do
      let(:is_unidentified) { true }

      it do
        is_expected.to have_attributes(
          is_unidentified: true,
          contested_issue_description: nil,
          nonrating_issue_description: nil,
          unidentified_issue_text: "decision text"
        )
      end
    end
  end

  context "#description" do
    subject { request_issue.description }

    context "when contested_issue_description present" do
      let(:request_issue) { rating_request_issue }
      it { is_expected.to eq("a rating request issue") }
    end

    context "when nonrating" do
      let(:request_issue) { nonrating_request_issue }
      it { is_expected.to eq("a category - a nonrating request issue description") }

      context "when contested_issue_description present" do
        let(:nonrating_contested_issue_description) { "nonrating contested" }
        it { is_expected.to eq("nonrating contested") }
      end
    end

    context "when unidentified" do
      let(:request_issue) { unidentified_issue }
      it { is_expected.to eq("an unidentified issue") }
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
      expect(rating_request_issue.contested_rating_issue.reference_id).to eq contested_rating_issue_reference_id
      expect(rating_request_issue.contested_rating_issue.decision_text).to eq "Left knee granted"
    end
  end

  context "#contested_benefit_type" do
    it "returns the benefit_type of the contested_rating_issue" do
      expect(rating_request_issue.contested_benefit_type).to eq :compensation
    end
  end

  context "#previous_request_issue" do
    let(:previous_higher_level_review) { create(:higher_level_review, receipt_date: review.receipt_date - 10.days) }

    let(:previous_end_product_establishment) do
      create(
        :end_product_establishment,
        :cleared,
        veteran_file_number: veteran.file_number,
        established_at: previous_higher_level_review.receipt_date - 100.days
      )
    end

    let!(:previous_request_issue) do
      create(
        :request_issue,
        review_request: previous_higher_level_review,
        contested_rating_issue_reference_id: higher_level_review_reference_id,
        contested_rating_issue_profile_date: profile_date,
        contested_issue_description: "a rating request issue",
        contention_reference_id: contention_reference_id,
        end_product_establishment: previous_end_product_establishment,
        description: "a rating request issue"
      ).tap(&:submit_for_processing!)
    end

    let(:associated_claims) do
      [{
        clm_id: previous_end_product_establishment.reference_id,
        bnft_clm_tc: previous_end_product_establishment.code
      }]
    end

    context "when contesting the same decision review" do
      let(:previous_contention) do
        Generators::Contention.build(
          id: contention_reference_id,
          claim_id: previous_end_product_establishment.reference_id,
          disposition: "allowed"
        )
      end

      let(:contested_decision_issue_id) do
        previous_contention
        previous_request_issue.sync_decision_issues!
        previous_request_issue.decision_issues.first.id
      end

      it "looks up the chain to the immediately previous request issue" do
        expect(rating_request_issue.previous_request_issue).to eq(previous_request_issue)
      end
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

    let(:previous_review) { create(:higher_level_review) }
    let!(:previous_request_issue) do
      create(
        :request_issue,
        review_request: previous_review,
        contested_rating_issue_reference_id: higher_level_review_reference_id,
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
        contested_rating_issue_reference_id: duplicate_appeal_reference_id,
        contested_issue_description: "Appealed injury",
        description: "Appealed injury"
      )
    end

    let!(:ratings) do
      Generators::Rating.build(
        participant_id: veteran.participant_id,
        promulgation_date: rating_promulgation_date,
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
        contested_rating_issue_reference_id: duplicate_reference_id,
        contested_issue_description: "Old injury",
        description: "Old injury"
      )
    end

    it "flags nonrating request issue as untimely when decision date is older than receipt_date" do
      nonrating_request_issue.decision_date = receipt_date - 400
      nonrating_request_issue.validate_eligibility!

      expect(nonrating_request_issue.untimely?).to eq(true)
    end

    it "flags rating request issue as untimely when promulgation_date is year+ older than receipt_date" do
      rating_request_issue.contested_rating_issue_reference_id = old_reference_id
      rating_request_issue.validate_eligibility!

      expect(rating_request_issue.untimely?).to eq(true)
    end

    it "flags duplicate rating request issue as in progress" do
      rating_request_issue.contested_rating_issue_reference_id = duplicate_reference_id
      rating_request_issue.validate_eligibility!

      expect(rating_request_issue.duplicate_of_rating_issue_in_active_review?).to eq(true)
      expect(rating_request_issue.ineligible_due_to).to eq(request_issue_in_progress)

      rating_request_issue.save!
      expect(request_issue_in_progress.duplicate_but_ineligible).to eq([rating_request_issue])
    end

    it "flags duplicate appeal as in progress" do
      rating_request_issue.contested_rating_issue_reference_id =
        appeal_request_issue_in_progress.contested_rating_issue_reference_id
      rating_request_issue.validate_eligibility!

      expect(rating_request_issue.duplicate_of_rating_issue_in_active_review?).to eq(true)
    end

    context "issues with previous decision reviews" do
      let(:contested_rating_issue_reference_id) { higher_level_review_reference_id }

      context "when the previous review is a higher level review" do
        let(:previous_review) { create(:higher_level_review) }

        context "when the current review is a higher level review" do
          it "is not eligible after a higher level review" do
            rating_request_issue.validate_eligibility!

            expect(rating_request_issue.higher_level_review_to_higher_level_review?).to eq(true)
            expect(rating_request_issue.ineligible_reason).to eq("higher_level_review_to_higher_level_review")
            expect(rating_request_issue.ineligible_due_to).to eq(previous_request_issue)

            rating_request_issue.save!
            expect(previous_request_issue.duplicate_but_ineligible).to eq([rating_request_issue])
          end
        end

        context "when the current review is a supplemental claim" do
          let(:review) do
            create(
              :supplemental_claim,
              veteran_file_number: veteran.file_number,
              legacy_opt_in_approved: legacy_opt_in_approved
            )
          end

          it "does not get flagged for previous higher level review" do
            rating_request_issue.validate_eligibility!

            expect(rating_request_issue.ineligible_reason).to_not eq("higher_level_review_to_higher_level_review")
          end
        end

        context "when the current review is an appeal" do
          let(:review) do
            create(
              :appeal,
              veteran: veteran,
              legacy_opt_in_approved: legacy_opt_in_approved
            )
          end

          it "is still eligible after a previous higher level review" do
            rating_request_issue.validate_eligibility!

            expect(rating_request_issue.ineligible_reason).to be_nil
          end
        end
      end

      context "when the previous review is an appeal" do
        let(:previous_review) { create(:appeal) }

        context "when the current review is a higher level review" do
          let(:review) do
            create(
              :higher_level_review,
              veteran_file_number: veteran.file_number,
              legacy_opt_in_approved: legacy_opt_in_approved
            )
          end

          it "is not eligible after an appeal" do
            rating_request_issue.validate_eligibility!

            expect(rating_request_issue.ineligible_reason).to eq("appeal_to_higher_level_review")
            expect(rating_request_issue.ineligible_due_to).to eq(previous_request_issue)
          end
        end

        context "when the current review is an appeal" do
          let(:review) do
            create(
              :appeal,
              veteran: veteran,
              legacy_opt_in_approved: legacy_opt_in_approved
            )
          end

          it "is not eligible after an appeal" do
            rating_request_issue.validate_eligibility!

            expect(rating_request_issue.ineligible_reason).to eq("appeal_to_appeal")
            expect(rating_request_issue.ineligible_due_to).to eq(previous_request_issue)
          end
        end
      end
    end

    context "Issues with legacy issues" do
      before do
        FeatureToggle.enable!(:intake_legacy_opt_in)

        # Active and eligible
        create(:legacy_appeal, vacols_case: create(
          :case,
          :status_active,
          bfkey: "vacols1",
          bfcorlid: "#{veteran.file_number}S",
          bfdnod: 3.days.ago,
          bfdsoc: 3.days.ago
        ))
        allow(AppealRepository).to receive(:issues).with("vacols1")
          .and_return(
            [
              Generators::Issue.build(id: "vacols1", vacols_sequence_id: 1, codes: %w[02 15 03 5250], disposition: nil),
              Generators::Issue.build(id: "vacols1", vacols_sequence_id: 2, codes: %w[02 15 03 5251], disposition: nil)
            ]
          )

        # Active and not eligible
        create(:legacy_appeal, vacols_case: create(
          :case,
          :status_active,
          bfkey: "vacols2",
          bfcorlid: "#{veteran.file_number}S",
          bfdnod: 4.years.ago,
          bfdsoc: 4.months.ago
        ))
        allow(AppealRepository).to receive(:issues).with("vacols2")
          .and_return(
            [
              Generators::Issue.build(id: "vacols2", vacols_sequence_id: 1, codes: %w[02 15 03 5243], disposition: nil),
              Generators::Issue.build(id: "vacols2", vacols_sequence_id: 2, codes: %w[02 15 03 5242], disposition: nil)
            ]
          )
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
        rating_request_issue.contested_rating_issue_reference_id = "before_ama_ref_id"
        rating_request_issue.validate_eligibility!
        expect(rating_request_issue.ineligible_reason).to eq("before_ama")
      end

      context "rating issue is from a RAMP decision" do
        let(:ramp_claim_id) { "ramp_claim_id" }

        it "does not flag rating issues before AMA" do
          rating_request_issue.contested_rating_issue_reference_id = "ramp_ref_id"

          rating_request_issue.validate_eligibility!

          expect(rating_request_issue.ineligible_reason).to be_nil
        end
      end

      context "rating issue is from a VACOLS legacy opt-in" do
        let(:rating_promulgation_date) { 10.years.ago }

        it "does not flag rating issues before AMA" do
          rating_request_issue.review_request.legacy_opt_in_approved = true
          rating_request_issue.vacols_id = "something"
          rating_request_issue.contested_rating_issue_reference_id = "xyz123"

          rating_request_issue.validate_eligibility!

          expect(rating_request_issue.contested_rating_issue).to_not be_nil
          expect(rating_request_issue.ineligible_reason).to be_nil
        end
      end
    end
  end

  context "#close_after_end_product_canceled!" do
    subject { rating_request_issue.close_after_end_product_canceled! }
    let(:end_product_establishment) { create(:end_product_establishment, :canceled) }

    it "closes the request issue" do
      subject
      expect(rating_request_issue.closed_at).to eq(Time.zone.now)
      expect(rating_request_issue.closed_status).to eq("end_product_canceled")
    end

    context "if the request issue is already closed" do
      let(:closed_at) { 1.day.ago }
      let(:closed_status) { "removed" }

      it "does not reclose the issue" do
        subject
        expect(rating_request_issue.closed_at).to eq(closed_at)
        expect(rating_request_issue.closed_status).to eq(closed_status)
      end
    end

    context "when there is a legacy issue optin" do
      let(:vacols_id) { vacols_issue.id }
      let(:vacols_sequence_id) { vacols_issue.isskey }
      let(:vacols_issue) { create(:case_issue, :disposition_remanded, isskey: 1) }
      let(:vacols_case) do
        create(:case, case_issues: [vacols_issue])
      end
      let!(:legacy_issue_optin) { create(:legacy_issue_optin, request_issue: rating_request_issue) }

      it "flags the legacy issue optin for rollback" do
        subject
        expect(rating_request_issue.closed_at).to eq(Time.zone.now)
        expect(legacy_issue_optin.reload.rollback_created_at).to eq(Time.zone.now)
      end
    end
  end

  context "#sync_decision_issues!" do
    let(:request_issue) { rating_request_issue.tap(&:submit_for_processing!) }
    subject { request_issue.sync_decision_issues! }

    context "when it has been processed" do
      let(:decision_sync_processed_at) { 1.day.ago }
      let!(:decision_issue) do
        rating_request_issue.decision_issues.create!(
          participant_id: veteran.participant_id,
          decision_review: rating_request_issue.review_request,
          benefit_type: review.benefit_type,
          disposition: "allowed",
          end_product_last_action_date: Time.zone.now
        )
      end

      before do
        request_issue.processed!
      end

      it "does nothing" do
        subject
        expect(rating_request_issue.decision_issues.count).to eq(1)
      end
    end

    context "when it hasn't been processed" do
      let(:ep_code) { "030HLRR" }
      let(:end_product_establishment) do
        create(:end_product_establishment,
               :cleared,
               veteran_file_number: veteran.file_number,
               established_at: review.receipt_date - 100.days,
               code: ep_code)
      end

      let!(:contention) do
        Generators::Contention.build(
          id: contention_reference_id,
          claim_id: end_product_establishment.reference_id,
          disposition: "allowed"
        )
      end

      context "with rating ep" do
        context "when associated rating exists" do
          let(:associated_claims) { [{ clm_id: end_product_establishment.reference_id, bnft_clm_tc: ep_code }] }

          context "when matching rating issues exist" do
            let!(:decision_issue_not_matching_disposition) do
              create(
                :decision_issue,
                decision_review: review,
                participant_id: veteran.participant_id,
                disposition: "denied",
                rating_issue_reference_id: contested_rating_issue_reference_id
              )
            end

            it "creates decision issues based on rating issues" do
              rating_request_issue.decision_sync_error = "previous error"
              subject
              expect(rating_request_issue.decision_issues.count).to eq(1)
              expect(rating_request_issue.decision_issues.first).to have_attributes(
                rating_issue_reference_id: contested_rating_issue_reference_id,
                disposition: "allowed",
                participant_id: veteran.participant_id,
                promulgation_date: ratings.promulgation_date,
                decision_text: "Left knee granted",
                profile_date: ratings.profile_date,
                decision_review_type: "HigherLevelReview",
                decision_review_id: review.id,
                benefit_type: "compensation",
                end_product_last_action_date: end_product_establishment.result.last_action_date.to_date
              )
              expect(rating_request_issue.processed?).to eq(true)
              expect(rating_request_issue.decision_sync_error).to be_nil
            end

            context "when decision issue with disposition and rating issue already exists" do
              let!(:preexisting_decision_issue) do
                create(
                  :decision_issue,
                  decision_review: review,
                  participant_id: veteran.participant_id,
                  disposition: "allowed",
                  rating_issue_reference_id: contested_rating_issue_reference_id
                )
              end

              it "links preexisting decision issue to request issue" do
                subject
                expect(rating_request_issue.decision_issues.count).to eq(1)
                expect(rating_request_issue.decision_issues.first).to eq(preexisting_decision_issue)
                expect(rating_request_issue.processed?).to eq(true)
              end
            end

            context "when syncing the end_product_establishment fails" do
              before do
                allow(end_product_establishment).to receive(
                  :on_decision_issue_sync_processed
                ).and_raise("DTA 040 failed")
              end

              it "does not processs" do
                expect { subject }.to raise_error("DTA 040 failed")
                expect(rating_request_issue.processed?).to eq(false)
              end
            end
          end

          context "when no matching rating issues exist" do
            let(:issues) do
              [{ reference_id: "xyz456", decision_text: "PTSD denied", contention_reference_id: "bad_id" }]
            end

            it "creates decision issues based on contention disposition" do
              subject
              expect(rating_request_issue.decision_issues.count).to eq(1)
              expect(rating_request_issue.decision_issues.first).to have_attributes(
                participant_id: veteran.participant_id,
                disposition: "allowed",
                description: "allowed: #{request_issue.description}",
                decision_review_type: "HigherLevelReview",
                profile_date: ratings.profile_date,
                promulgation_date: ratings.promulgation_date,
                decision_review_id: review.id,
                benefit_type: "compensation",
                end_product_last_action_date: end_product_establishment.result.last_action_date.to_date
              )
              expect(rating_request_issue.processed?).to eq(true)
            end
          end
        end

        context "when no associated rating exists" do
          it "resubmits for processing" do
            subject
            expect(rating_request_issue.decision_issues.count).to eq(0)
            expect(rating_request_issue.processed?).to eq(false)
            expect(rating_request_issue.decision_sync_attempted_at).to eq(Time.zone.now)
          end
        end
      end

      context "with nonrating ep" do
        let(:request_issue) { nonrating_request_issue.tap(&:submit_for_processing!) }

        let(:ep_code) { "030HLRNR" }

        let!(:contention) do
          Generators::Contention.build(
            id: contention_reference_id,
            claim_id: end_product_establishment.reference_id,
            disposition: "allowed"
          )
        end

        it "creates decision issues based on contention disposition" do
          subject
          expect(request_issue.decision_issues.count).to eq(1)
          expect(request_issue.decision_issues.first).to have_attributes(
            participant_id: veteran.participant_id,
            disposition: "allowed",
            decision_review_type: "HigherLevelReview",
            decision_review_id: review.id,
            benefit_type: "compensation",
            end_product_last_action_date: end_product_establishment.result.last_action_date.to_date
          )
          expect(request_issue.processed?).to eq(true)
        end

        context "when there is no disposition" do
          before do
            Fakes::VBMSService.disposition_records = nil
          end
          it "raises an error" do
            expect { subject }.to raise_error(RequestIssue::ErrorCreatingDecisionIssue)
            expect(nonrating_request_issue.processed?).to eq(false)
          end
        end
      end
    end
  end
end
