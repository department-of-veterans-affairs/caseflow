# frozen_string_literal: true

describe RequestIssue, :all_dbs do
  before do
    Timecop.freeze(Time.zone.now)
    FeatureToggle.enable!(:use_ama_activation_date)
  end

  after { FeatureToggle.disable!(:use_ama_activation_date) }

  let(:contested_rating_issue_reference_id) { "abc123" }
  let(:contested_rating_decision_reference_id) { nil }
  let(:profile_date) { Time.zone.now.to_s }
  let(:contention_reference_id) { "1234" }
  let(:nonrating_contention_reference_id) { "5678" }
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
  let(:ineligible_reason) { nil }
  let(:edited_description) { nil }
  let(:covid_timeliness_exempt) { nil }

  let(:review) do
    create(
      :higher_level_review,
      veteran_file_number: veteran.file_number,
      legacy_opt_in_approved: legacy_opt_in_approved,
      same_office: same_office,
      benefit_type: benefit_type,
      receipt_date: receipt_date,
      intake: create(:intake)
    )
  end

  let(:receipt_date) { post_ama_start_date }

  let(:rating_promulgation_date) { (receipt_date - 40.days).in_time_zone }

  let!(:ratings) do
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: rating_promulgation_date,
      profile_date: (receipt_date - 50.days).in_time_zone,
      issues: issues,
      decisions: decisions,
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

  let(:decisions) do
    [
      {
        diagnostic_text: "right knee",
        disability_id: contested_rating_decision_reference_id,
        original_denial_date: rating_promulgation_date - 7.days
      }
    ]
  end

  let!(:rating_request_issue) do
    create(
      :request_issue,
      decision_review: review,
      contested_rating_issue_reference_id: contested_rating_issue_reference_id,
      contested_rating_decision_reference_id: contested_rating_decision_reference_id,
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
      closed_status: closed_status,
      ineligible_reason: ineligible_reason,
      edited_description: edited_description,
      covid_timeliness_exempt: covid_timeliness_exempt
    )
  end

  let!(:nonrating_request_issue) do
    create(
      :request_issue,
      decision_review: review,
      nonrating_issue_description: "a nonrating request issue description",
      contested_issue_description: nonrating_contested_issue_description,
      nonrating_issue_category: "a category",
      decision_date: 1.day.ago,
      decision_sync_processed_at: decision_sync_processed_at,
      end_product_establishment: end_product_establishment,
      contention_reference_id: nonrating_contention_reference_id,
      benefit_type: benefit_type
    )
  end

  let!(:rating_decision_request_issue) do
    create(
      :request_issue,
      :rating_decision,
      contested_rating_issue_profile_date: profile_date,
      decision_review: review
    )
  end

  let(:nonrating_contested_issue_description) { nil }

  let!(:unidentified_issue) do
    create(
      :request_issue,
      decision_review: review,
      unidentified_issue_text: "an unidentified issue",
      is_unidentified: true,
      decision_date: 5.days.ago
    )
  end

  let(:associated_claims) { [] }

  context "#save" do
    subject { rating_request_issue.save }

    context "when ineligible_reason is set" do
      let(:ineligible_reason) { "appeal_to_appeal" }

      it "closes the issue as ineligible" do
        subject

        expect(rating_request_issue).to have_attributes(
          closed_at: Time.zone.now,
          closed_status: "ineligible"
        )
      end
    end
  end

  context "#remanded?" do
    subject { rating_request_issue.remanded? }

    context "when not contesting a decision issue" do
      it { is_expected.to be_falsey }
    end

    context "when contesting a decision issue" do
      let!(:decision_issue) { create(:decision_issue, decision_review: another_review, disposition: disposition) }
      let(:another_review) { create(:higher_level_review) }
      let(:disposition) { nil }
      let(:contested_decision_issue_id) { decision_issue.id }

      context "when the decision issue has a remanded disposition" do
        let(:disposition) { "remanded" }

        it { is_expected.to eq true }
      end

      context "when the decision issue does not have a remand disposition" do
        let(:disposition) { "granted" }

        it { is_expected.to be_falsey }

        context "when the decision issue is from a remand supplemental claim" do
          let(:another_review) { create(:supplemental_claim, decision_review_remanded: create(:appeal)) }

          it { is_expected.to be_falsey }

          context "when the decision issue from the same review (it is a correction)" do
            let(:review) { another_review }

            it { is_expected.to eq true }
          end
        end
      end
    end
  end

  context "#remand_type" do
    subject { rating_request_issue.remand_type }

    context "when not contesting a decision issue" do
      it { is_expected.to be_falsey }
    end

    context "when contesting a decision issue" do
      let!(:decision_issue) { create(:decision_issue, decision_review: another_review, disposition: disposition) }
      let(:another_review) { create(:higher_level_review) }
      let(:disposition) { nil }
      let(:contested_decision_issue_id) { decision_issue.id }

      context "when the decision issue has a remanded disposition" do
        context "when the decision issue has a DTA disposition" do
          let(:disposition) { "DTA Error" }

          it { is_expected.to eq "duty_to_assist" }
        end

        context "when the decision issue has a difference of opinion disposition" do
          let(:disposition) { "Difference of Opinion" }

          it { is_expected.to eq "difference_of_opinion" }
        end
      end

      context "when the decision issue does not have a remand disposition" do
        let(:disposition) { "granted" }

        it { is_expected.to be_falsey }

        context "when the decision issue is from a remand supplemental claim" do
          let(:another_review) { create(:supplemental_claim, decision_review_remanded: create(:appeal)) }

          it { is_expected.to be_falsey }

          context "when the decision issue from the same review (it is a correction)" do
            let(:review) { another_review }

            let(:original_request_issue) do
              create(
                :request_issue,
                decision_review: create(:higher_level_review),
                decision_issues: [original_decision_issue]
              )
            end
            let(:original_decision_issue) { create(:decision_issue, disposition: original_disposition) }
            let(:corrected_request_issue) do
              create(:request_issue, decision_review: review, contested_decision_issue_id: original_decision_issue.id)
            end

            let!(:decision_issue) do
              create(
                :decision_issue,
                decision_review: review,
                disposition: disposition,
                request_issues: [corrected_request_issue]
              )
            end

            context "when the original disposition is DOO" do
              let(:original_disposition) { DecisionIssue::DIFFERENCE_OF_OPINION }

              it { is_expected.to eq "difference_of_opinion" }
            end

            context "when the original disposition is DTA" do
              let(:original_disposition) { DecisionIssue::DTA_ERROR }

              it { is_expected.to eq "duty_to_assist" }
            end
          end
        end
      end
    end
  end

  context "legacy_optin" do
    let!(:legacy_appeal) do
      create(:legacy_appeal, vacols_case:
        create(
          :case,
          :status_active,
          bfkey: vacols_id,
          bfcorlid: "#{veteran.file_number}S",
          bfdc: "G",
          bfddec: 3.days.ago,
          folder: create(:folder, tidcls: folder_date),
          case_issues: [
            create(:case_issue, :ankylosis_of_hip),
            create(:case_issue, :limitation_of_thigh_motion_extension)
          ]
        ))
    end
    let(:vacols_id) { "vacols7" }
    let(:vacols_sequence_id) { 1 }
    let(:decision_date) { 3.days.ago.to_date }
    let(:folder_date) { 5.days.ago.to_date }
    subject { rating_request_issue.handle_legacy_issues! }
    it "saves legacy appeal disposition and decision date " do
      subject
      expect(rating_request_issue.legacy_issue_optin.original_legacy_appeal_disposition_code).to eq "G"
      expect(rating_request_issue.legacy_issue_optin.original_legacy_appeal_decision_date).to eq(decision_date)
      expect(rating_request_issue.legacy_issue_optin.folder_decision_date).to eq(folder_date)
    end
  end

  context "#contention" do
    let(:end_product_establishment) { create(:end_product_establishment, :active) }
    let!(:contention) do
      Generators::Contention.build(
        id: contention_reference_id,
        claim_id: end_product_establishment.reference_id,
        disposition: "allowed"
      )
    end

    it "returns matching contention" do
      expect(rating_request_issue.contention.id.to_s).to eq(contention_reference_id.to_s)
    end
  end

  context "#contention_missing?" do
    let(:end_product_establishment) { create(:end_product_establishment, :active) }
    subject { rating_request_issue.contention_missing? }

    context "contention_reference_id points at non-existent contention" do
      let(:contention_reference_id) { "9999" }

      it { is_expected.to eq(true) }
    end

    context "contention_reference_id points at existing contention" do
      let!(:contention) do
        Generators::Contention.build(
          id: contention_reference_id,
          claim_id: end_product_establishment.reference_id,
          disposition: "allowed"
        )
      end

      it { is_expected.to eq(false) }
    end

    context "contention_reference_id is nil" do
      let(:contention_reference_id) { nil }

      it { is_expected.to eq(false) }
    end
  end

  context "#editable?" do
    subject { rating_request_issue.editable? }
    let(:receipt_date) { 1.month.ago }
    let(:end_product_establishment) do
      create(
        :end_product_establishment,
        :active,
        established_at: receipt_date + 5.days,
        veteran: veteran
      )
    end

    it { is_expected.to be true }

    context "when there's a connected rating" do
      before do
        Generators::PromulgatedRating.build(
          participant_id: veteran.participant_id,
          profile_date: receipt_date + 10.days,
          promulgation_date: receipt_date + 10.days,
          issues: [
            {
              reference_id: "ref_id1", decision_text: "PTSD denied",
              contention_reference_id: rating_request_issue.contention_reference_id
            }
          ],
          associated_claims: [{ clm_id: end_product_establishment.reference_id, bnft_clm_tc: "030HLRR" }]
        )
      end

      it "returns false" do
        expect(subject).to eq false
      end
    end
  end

  context "#exam_requested?" do
    subject { rating_request_issue.exam_requested? }
    before { FeatureToggle.enable!(:detect_contention_exam) }
    after { FeatureToggle.disable!(:detect_contention_exam) }

    context "when there is no contention" do
      let(:contention_reference_id) { nil }

      it { is_expected.to be_falsey }
    end

    context "when there is no end product establishment" do
      let(:end_product_establishment) { nil }

      it { is_expected.to be_falsey }
    end

    context "when there is a contention" do
      let(:end_product_establishment) { create(:end_product_establishment, :active) }
      let(:contention_reference_id) { 1234 }
      let(:orig_source_type_code) { "APP" }
      let!(:contention) do
        Generators::BgsContention.build(
          reference_id: contention_reference_id,
          claim_id: end_product_establishment.reference_id,
          orig_source_type_code: orig_source_type_code
        )
      end

      it { is_expected.to be_falsey }

      context "when there is an exam scheduled" do
        let(:orig_source_type_code) { "EXAM" }

        it { is_expected.to be true }
      end
    end
  end

  context "#guess_benefit_type" do
    context "issue is unidentified" do
      it "returns 'unidentified'" do
        expect(unidentified_issue.guess_benefit_type).to eq "unidentified"
      end
    end

    context "issue is ineligible" do
      let(:ineligible_reason) { :duplicate_of_rating_issue_in_active_review }

      it "returns 'ineligible'" do
        expect(rating_request_issue.guess_benefit_type).to eq "ineligible"
      end
    end

    context "issue has a contested_decision_issue" do
      let(:decision_issue) { create(:decision_issue, benefit_type: "education") }
      let(:request_issue) { create(:request_issue, contested_decision_issue: decision_issue) }

      it "returns the parent decision issue's benefit_type" do
        expect(request_issue.guess_benefit_type).to eq "education"
      end
    end

    it "defaults to 'unknown'" do
      expect(rating_request_issue.guess_benefit_type).to eq "unknown"
    end
  end

  context "#requires_record_request_task?" do
    context "issue is ineligible" do
      let(:benefit_type) { "education" }

      before do
        allow(nonrating_request_issue).to receive(:eligible?).and_return(false)
      end

      it "does not require record request task" do
        expect(nonrating_request_issue.requires_record_request_task?).to eq false
      end
    end

    context "issue is unidentified" do
      it "does not require record request task" do
        expect(unidentified_issue.requires_record_request_task?).to eq false
      end
    end

    context "issue is not a non-compensation line of business" do
      let(:benefit_type) { "compensation" }

      it "does not require a record request task" do
        expect(nonrating_request_issue.requires_record_request_task?).to eq false
      end
    end

    context "issue is non-compensation" do
      let(:benefit_type) { "education" }

      it "requires a record request task" do
        expect(nonrating_request_issue.requires_record_request_task?).to eq true
      end
    end
  end

  context ".requires_processing" do
    before do
      rating_request_issue.submit_for_processing!(delay: 1.day)
      nonrating_request_issue.tap do |issue|
        issue.submit_for_processing!
        issue.update!(
          decision_sync_last_submitted_at: (RequestIssue.processing_retry_interval_hours + 1).hours.ago
        )
      end
    end

    it "respects the delay" do
      expect(rating_request_issue.submitted_and_ready?).to eq(false)
      expect(rating_request_issue.submitted?).to eq(true)
      expect(nonrating_request_issue.submitted?).to eq(true)

      todo = RequestIssue.requires_processing
      expect(todo).to_not include(rating_request_issue)
      expect(todo).to include(nonrating_request_issue)
    end

    it "keeps trying for #{RequestIssue::REQUIRES_PROCESSING_WINDOW_DAYS} days" do
      Timecop.travel(Time.zone.now + RequestIssue::REQUIRES_PROCESSING_WINDOW_DAYS.days - 1.day) do
        expect(nonrating_request_issue.expired_without_processing?).to eq(false)
      end
    end

    it "gives up after #{RequestIssue::REQUIRES_PROCESSING_WINDOW_DAYS} days" do
      Timecop.travel(Time.zone.now + RequestIssue::REQUIRES_PROCESSING_WINDOW_DAYS.days) do
        expect(nonrating_request_issue.expired_without_processing?).to eq(true)
      end
    end
  end

  context ".rating" do
    subject { RequestIssue.rating }

    it "filters by rating issues" do
      expect(subject.length).to eq(3)

      expect(subject.find_by(id: rating_request_issue.id)).to_not be_nil
      expect(subject.find_by(id: rating_decision_request_issue.id)).to_not be_nil
      expect(subject.find_by(id: unidentified_issue.id)).to_not be_nil
    end
  end

  context ".rating_issue" do
    subject { RequestIssue.rating_issue }

    it "filters by rating_issue issues" do
      expect(subject.length).to eq(1)
    end
  end

  context ".rating_decision" do
    subject { RequestIssue.rating_decision }

    it "filters by rating_decision issues" do
      expect(subject.length).to eq(1)
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

  context "remove!" do
    let(:decision_issue) { create(:decision_issue) }
    let!(:request_issue1) { create(:request_issue, decision_issues: [decision_issue]) }

    subject { request_issue1.remove! }

    context "when a decision issue is shared between two request issues" do
      let!(:request_issue2) { create(:request_issue, decision_issues: [decision_issue]) }

      it "does not soft delete a decision issue" do
        expect(RequestDecisionIssue.count).to eq 2
        subject
        expect(DecisionIssue.find_by(id: decision_issue.id)).to_not be_nil
        expect(RequestDecisionIssue.count).to eq 1
      end
    end

    context "when request issue has many decision issues" do
      let(:decision_issue2) { create(:decision_issue) }
      let!(:request_issue1) do
        create(:request_issue, decision_issues: [decision_issue, decision_issue2])
      end

      it "soft deletes all decision issues" do
        expect(RequestDecisionIssue.count).to eq 2
        subject
        expect(DecisionIssue.count).to eq 0
        expect(DecisionIssue.unscoped.count).to eq 2
        expect(RequestDecisionIssue.count).to eq 0
        expect(RequestDecisionIssue.unscoped.count).to eq 2
      end
    end

    context "when a decision issue is not shared between two request issues" do
      it "soft deletes a decision issue" do
        expect(RequestDecisionIssue.count).to eq 1
        subject
        expect(DecisionIssue.find_by(id: decision_issue.id)).to be_nil
        expect(DecisionIssue.unscoped.find_by(id: decision_issue.id)).to_not be_nil
        expect(RequestDecisionIssue.count).to eq 0
        expect(RequestDecisionIssue.unscoped.count).to eq 1
      end
    end

    context "when a request issue is removed after it has been submitted, before it has been processed" do
      let!(:request_issue1) do
        create(:request_issue, decision_sync_submitted_at: 1.day.ago, decision_sync_processed_at: nil)
      end

      it "cancels the decision sync job" do
        subject
        expect(request_issue1.decision_sync_canceled_at).to eq Time.zone.now
      end
    end
  end

  context ".active" do
    subject { RequestIssue.active }

    let!(:closed_request_issue) { create(:request_issue, :removed) }

    it "filters by whether the closed_at is nil" do
      expect(subject.find_by(id: closed_request_issue.id)).to be_nil
    end
  end

  context ".active_or_decided_or_withdrawn" do
    subject { RequestIssue.active_or_decided_or_withdrawn }

    let!(:decided_request_issue) { create(:request_issue, :decided) }
    let!(:removed_request_issue) { create(:request_issue, :removed) }
    let!(:withdrawn_request_issue) { create(:request_issue, :withdrawn) }
    let!(:open_eligible_request_issue) { create(:request_issue) }

    it "returns open eligible or closed decided or withdrawn issues" do
      expect(subject.find_by(id: removed_request_issue.id)).to be_nil
      expect(subject.find_by(id: decided_request_issue.id)).to_not be_nil
      expect(subject.find_by(id: withdrawn_request_issue.id)).to_not be_nil
      expect(subject.find_by(id: open_eligible_request_issue.id)).to_not be_nil
    end
  end

  context "#original_contention_ids" do
    subject { rating_request_issue.original_contention_ids }

    let(:original_request_issues) do
      [
        create(:request_issue, contention_reference_id: "101"),
        create(:request_issue, contention_reference_id: "121")
      ]
    end
    let(:disposition) { "granted" }
    let!(:decision_issue) { create(:decision_issue, request_issues: original_request_issues, disposition: disposition) }

    context "when there is not a contested decision issue" do
      let(:contested_decision_issue_id) { nil }

      it { is_expected.to be_falsey }
    end

    context "when there is a contested decision issue" do
      let(:contested_decision_issue_id) { decision_issue.id }

      context "when the decision issue does not have a dta disposition" do
        it { is_expected.to be_falsey }
      end

      context "when the decision issue has a dta disposition" do
        let(:disposition) { "DTA Error" }

        it "includes an array of the contention reference IDs from the decision issues request issues" do
          expect(subject).to match_array([101, 121])
        end
      end
    end
  end

  context "limited_poa" do
    let(:previous_dr) { create(:higher_level_review) }
    let(:previous_ri) { create(:request_issue, decision_review: previous_dr, end_product_establishment: previous_epe) }
    let(:previous_epe) { create(:end_product_establishment, reference_id: previous_claim_id) }
    let(:decision_issue) { create(:decision_issue, decision_review: previous_dr, request_issues: [previous_ri]) }

    context "when there is no previous request issue" do
      let(:contested_decision_issue_id) { nil }

      it "returns nil" do
        expect(rating_request_issue.limited_poa_code).to be_nil
        expect(rating_request_issue.limited_poa_access).to be_nil
      end
    end

    context "when there is a previous request issue" do
      let(:contested_decision_issue_id) { decision_issue.id }

      context "when the previous request issue does not have an EPE" do
        let(:previous_epe) { nil }

        it "returns nil" do
          expect(rating_request_issue.limited_poa_code).to be_nil
          expect(rating_request_issue.limited_poa_access).to be_nil
        end
      end

      context "when the epe's result does not have a limited poa" do
        let(:previous_claim_id) { "NoLimitedPOA" }

        it "returns nil" do
          expect(rating_request_issue.limited_poa_code).to be_nil
          expect(rating_request_issue.limited_poa_access).to be_nil
        end
      end

      context "when there is an limited POA with access" do
        let(:previous_claim_id) { "HAS_LIMITED_POA_WITH_ACCESS" }
        it "returns the established end product's limited POA, changes Y to true" do
          expect(rating_request_issue.limited_poa_code).to eq("OU3")
          expect(rating_request_issue.limited_poa_access).to be true
        end
      end

      context "when there is an limited POA without access" do
        let(:previous_claim_id) { "HAS_LIMITED_POA_WITHOUT_ACCESS" }
        it "returns the established end product's limited POA, with false for access" do
          expect(rating_request_issue.limited_poa_code).to eq("007")
          expect(rating_request_issue.limited_poa_access).to be false
        end
      end
    end
  end

  context "#end_product_code" do
    subject { rating_request_issue.end_product_code }

    context "when decision review is not processed in caseflow" do
      let(:benefit_type) { "education" }
      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when request issue is ineligible" do
      let(:closed_status) { "ineligible" }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when decision review is processed in caseflow" do
      it "calls EndProductCodeSelector" do
        expect_any_instance_of(EndProductCodeSelector).to receive(:call).once

        subject
      end
    end
  end

  context "#corrected?" do
    let(:request_issue) { create(:request_issue, corrected_by_request_issue_id: corrected_by_id) }

    subject { request_issue.corrected? }

    context "when corrected" do
      let(:corrected_by_id) { create(:request_issue).id }
      it { is_expected.to eq true }
    end

    context "when not corrected" do
      let(:corrected_by_id) { nil }
      it { is_expected.to eq false }
    end
  end

  context "#ui_hash" do
    context "when there is a previous request issue in active review" do
      let!(:ratings) do
        Generators::PromulgatedRating.build(
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
          decision_review: previous_higher_level_review,
          contested_rating_issue_reference_id: higher_level_review_reference_id,
          contention_reference_id: "2222",
          end_product_establishment: active_epe,
          contention_removed_at: nil,
          ineligible_reason: nil
        )
      end

      let!(:ineligible_request_issue) do
        create(
          :request_issue,
          decision_review: new_higher_level_review,
          contested_rating_issue_reference_id: higher_level_review_reference_id,
          contention_reference_id: "3333",
          ineligible_reason: :duplicate_of_rating_issue_in_active_review,
          ineligible_due_to: request_issue_in_active_review
        )
      end

      it "returns the review title of the request issue in active review" do
        expect(ineligible_request_issue.serialize).to include(
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
        nonrating_issue_category: nonrating_issue_category,
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
    let(:nonrating_issue_category) { nil }
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

    context "when nonrating_issue_category is set" do
      let(:nonrating_issue_category) { "other" }

      it do
        is_expected.to have_attributes(
          nonrating_issue_category: "other",
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

  context "#move_stream!" do
    subject { request_issue.move_stream!(new_appeal_stream: new_appeal_stream, closed_status: closed_status) }
    let(:closed_status) { "docket_switch" }
    let(:review) { create(:appeal) }
    let(:new_appeal_stream) { create(:appeal, veteran_file_number: veteran.file_number) }
    let(:request_issue) { create(:request_issue, nonrating_issue_description: "Moved issue", decision_review: review) }

    it "copies the request issue to the new stream and closes with the provided status" do
      subject
      expect(request_issue.closed_status).to eq closed_status
      expect(request_issue.closed_at).to eq Time.zone.now

      request_issue_copy = new_appeal_stream.reload.request_issues.first

      expect(request_issue_copy.nonrating_issue_description).to eq "Moved issue"
      expect(request_issue_copy.created_at).to be_within(1.second).of Time.zone.now
    end

    context "the request issue's decision review is not an appeal" do
      let(:review) { create(:higher_level_review) }

      it { is_expected.to be_nil }
    end
  end

  context "#description" do
    subject { request_issue.description }

    context "when contested_issue_description present" do
      let(:request_issue) { rating_request_issue }
      it { is_expected.to eq("a rating request issue") }
    end

    context "when description is edited" do
      let(:request_issue) { rating_request_issue }
      let(:edited_description) { "edited description" }
      it { is_expected.to eq(edited_description) }
    end

    context "when description returns empty string" do
      let(:request_issue) { rating_request_issue }
      let(:edited_description) { "" }

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
    it "munges the decision_review_type appropriately" do
      expect(rating_request_issue.review_title).to eq "Higher-Level Review"
    end
  end

  context "#contested_rating_issue" do
    it "returns the RatingIssue that prompted the RequestIssue" do
      expect(rating_request_issue.contested_rating_issue.reference_id).to eq contested_rating_issue_reference_id
      expect(rating_request_issue.contested_rating_issue.decision_text).to eq "Left knee granted"
    end
  end

  context "#contested_rating_decision" do
    before { FeatureToggle.enable!(:contestable_rating_decisions) }
    after { FeatureToggle.disable!(:contestable_rating_decisions) }

    let(:contested_rating_issue_reference_id) { nil }
    let(:contested_rating_decision_reference_id) { "some-disability-id" }

    it "returns the RatingDecision that prompted the RequestIssue" do
      expect(rating_request_issue.contested_rating_decision.reference_id).to eq contested_rating_decision_reference_id
      expect(rating_request_issue.contested_rating_issue).to be_nil
      expect(rating_request_issue.contested_rating_decision.decision_text).to match(/right knee/)
    end
  end

  context "#contested_benefit_type" do
    subject { rating_request_issue.contested_benefit_type }
    it "returns the benefit_type of the contested_rating_issue" do
      expect(subject).to eq :compensation
    end

    context "when the contested issue is a rating decision issue" do
      let(:contested_rating_issue_reference_id) { nil }
      let(:contested_rating_decision_reference_id) { "rating_decision_ref_id" }

      it "returns compensation" do
        expect(subject).to eq :compensation
      end
    end

    context "when the contested issue is neither a rating issue nor a rating decision" do
      let(:contested_rating_issue_reference_id) { nil }
      let(:contested_rating_decision_reference_id) { nil }

      it "calls guess_benefit_type" do
        expect(rating_request_issue).to receive(:guess_benefit_type)

        subject
      end
    end
  end

  context "#previous_request_issue" do
    let(:previous_higher_level_review) do
      create(
        :higher_level_review,
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date - 10.days
      )
    end

    let(:previous_end_product_establishment) do
      create(
        :end_product_establishment,
        :cleared,
        veteran_file_number: veteran.file_number,
        established_at: previous_higher_level_review.receipt_date - 100.days
      )
    end

    let(:previous_contention_ref_id) { "4444" }

    let!(:previous_request_issue) do
      create(
        :request_issue,
        decision_review: previous_higher_level_review,
        contested_rating_issue_reference_id: higher_level_review_reference_id,
        contested_rating_issue_profile_date: profile_date,
        contested_issue_description: "a rating request issue",
        contention_reference_id: previous_contention_ref_id,
        end_product_establishment: previous_end_product_establishment
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
          id: previous_contention_ref_id,
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

  context "#rating?, #nonrating?" do
    let(:request_issue) { rating_request_issue }

    context "when there is an associated rating issue" do
      let(:contested_rating_issue_reference_id) { "123" }

      it "rating? is true" do
        expect(request_issue.rating?).to be true
      end

      it "nonrating? is false" do
        expect(request_issue.nonrating?).to be(false)
      end
    end

    context "verified unidentified issue returns true for rating" do
      let!(:request_issue) { create(:request_issue, verified_unidentified_issue: true) }

      it "rating? is true" do
        expect(request_issue.rating?).to be true
      end

      it "nonrating? is false" do
        expect(request_issue.nonrating?).to be(false)
      end
    end

    context "where there is an associated rating decision" do
      let(:contested_rating_decision_reference_id) { "123" }

      it "rating? is true" do
        expect(request_issue.rating?).to be true
      end

      it "nonrating? is false" do
        expect(request_issue.nonrating?).to be(false)
      end
    end

    context "when the request issue is from a dta on a previous rating issue" do
      let(:contested_rating_issue_reference_id) { nil }
      let(:contested_decision_issue_id) { decision_issue.id }
      let(:previous_review) { create(:higher_level_review) }
      let(:original_request_issue) do
        create(
          :request_issue,
          decision_review: previous_review,
          contested_rating_issue_reference_id: "123"
        )
      end
      let(:decision_issue) do
        create(
          :decision_issue,
          decision_review: previous_review,
          request_issues: [original_request_issue]
        )
      end

      it "rating? is true" do
        expect(request_issue.rating?).to be true
      end

      it "nonrating? is false" do
        expect(request_issue.nonrating?).to be(false)
      end
    end

    context "when it's a nonrating issue" do
      let(:request_issue) { nonrating_request_issue }

      it "rating? is falsey" do
        expect(request_issue.rating?).to be_falsey
      end

      it "nonrating? is true" do
        expect(request_issue.nonrating?).to be(true)
      end
    end

    context "when the contested issue is a decision issue on an unidentified request issue" do
      let(:contested_rating_issue_reference_id) { nil }
      let(:other_request_issue) { unidentified_issue }
      let!(:decision_issue) { create(:decision_issue, request_issues: [other_request_issue]) }
      let(:contested_decision_issue_id) { decision_issue.id }

      it "rating is true" do
        expect(request_issue.rating?).to be true
      end

      it "nonrating? is false" do
        expect(request_issue.nonrating?).to be false
      end
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
    let(:closed_at) { nil }
    let(:previous_contention_reference_id) { "8888" }
    let(:correction_type) { nil }

    let(:previous_review) { create(:higher_level_review) }
    let!(:previous_request_issue) do
      create(
        :request_issue,
        decision_review: previous_review,
        contested_rating_issue_reference_id: higher_level_review_reference_id,
        contention_reference_id: previous_contention_reference_id,
        closed_at: 2.months.ago
      )
    end

    let(:appeal_in_progress) do
      create(:appeal, veteran_file_number: veteran.file_number).tap(&:create_tasks_on_intake_success!)
    end
    let(:appeal_request_issue_in_progress) do
      create(
        :request_issue,
        decision_review: appeal_in_progress,
        contested_rating_issue_reference_id: duplicate_appeal_reference_id,
        contested_issue_description: "Appealed injury"
      )
    end

    let!(:ratings) do
      Generators::PromulgatedRating.build(
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
            contention_reference_id: previous_contention_reference_id
          }
        ]
      )
      Generators::PromulgatedRating.build(
        participant_id: veteran.participant_id,
        promulgation_date: receipt_date - 400.days,
        profile_date: receipt_date - 450.days,
        issues: [
          { reference_id: old_reference_id, decision_text: "Really old injury" }
        ]
      )
      Generators::PromulgatedRating.build(
        participant_id: veteran.participant_id,
        promulgation_date: ama_start_date - 5.days,
        profile_date: ama_start_date - 10.days,
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
        correction_type: correction_type,
        contested_rating_issue_reference_id: duplicate_reference_id,
        contested_issue_description: "Old injury",
        closed_at: closed_at,
        contested_decision_issue_id: contested_decision_issue_id
      )
    end

    it "flags nonrating request issue as untimely when decision date is older than receipt_date" do
      nonrating_request_issue.decision_date = receipt_date - 400.days
      nonrating_request_issue.validate_eligibility!

      expect(nonrating_request_issue.untimely?).to eq(true)
    end

    it "flags unidentified request issue as untimely when decision date is older than receipt_date" do
      unidentified_issue.decision_date = receipt_date - 450.days
      unidentified_issue.validate_eligibility!

      expect(unidentified_issue.untimely?).to eq(true)
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

    context "when duplicate request issue is a correction" do
      let(:correction_type) { "control" }

      it "does not flag the correction issue as a duplicate" do
        rating_request_issue.validate_eligibility!
        expect(rating_request_issue.ineligible_reason).to be_nil
      end
    end

    context "when rating issue is missing associated_rating" do
      let(:duplicate_reference_id) { nil }
      let(:contested_rating_issue_reference_id) { nil }

      it "does not mark issue as duplicate of another issue missing an associated rating" do
        rating_request_issue.validate_eligibility!
        expect(rating_request_issue.ineligible_reason).to be_nil
      end
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
      let!(:nod_date) { 3.days.ago }
      let!(:soc_date) { 3.days.ago }
      let(:vacols_id) { "vacols1" }
      let(:vacols_sequence_id) { 1 }

      before do
        create(:legacy_appeal, vacols_case: create(
          :case,
          :status_active,
          bfkey: vacols_id,
          bfcorlid: "#{veteran.file_number}S",
          bfdnod: nod_date,
          bfdsoc: soc_date
        ))
        allow(AppealRepository).to receive(:issues).with(vacols_id)
          .and_return(
            [
              Generators::Issue.build(id: vacols_id, vacols_sequence_id: 1, codes: %w[02 15 03 5250], disposition: nil),
              Generators::Issue.build(id: vacols_id, vacols_sequence_id: 2, codes: %w[02 15 03 5251], disposition: nil)
            ]
          )
      end

      context "when legacy opt in is not approved" do
        let(:legacy_opt_in_approved) { false }

        it "flags issues with connected issues if legacy opt in is not approved" do
          rating_request_issue.validate_eligibility!

          expect(rating_request_issue.ineligible_reason).to eq("legacy_issue_not_withdrawn")
        end
      end

      context "when legacy opt in is approved" do
        let(:receipt_date) { Time.zone.today }
        let(:legacy_opt_in_approved) { true }

        context "when legacy issue is eligible" do
          let(:soc_date) { receipt_date - 3.days }
          let(:nod_date) { receipt_date - 3.days }

          it "does not mark issue ineligible" do
            rating_request_issue.validate_eligibility!

            expect(rating_request_issue.ineligible_reason).to be_nil
          end
        end

        context "when legacy issue is not eligible" do
          let(:nod_date) { 4.years.ago }
          let(:soc_date) { 4.months.ago }

          it "flags issues connected to ineligible appeals if legacy opt in is approved" do
            rating_request_issue.validate_eligibility!

            expect(rating_request_issue.ineligible_reason).to eq("legacy_appeal_not_eligible")
          end
        end

        context "when there is a timeliness exemption" do
          let(:covid_timeliness_exempt) { true }

          context "NOD date is eligible with exemption" do
            let(:nod_date) { Constants::DATES["NOD_COVID_ELIGIBLE"].to_date + 1.day }
            let(:soc_date) { Constants::DATES["SOC_COVID_ELIGIBLE"].to_date - 1.day }

            it "is eligible" do
              rating_request_issue.validate_eligibility!
              expect(rating_request_issue.ineligible_reason).to be_nil
            end
          end

          context "SOC date is eligible with exemption" do
            let(:nod_date) { Constants::DATES["NOD_COVID_ELIGIBLE"].to_date - 1.day }
            let(:soc_date) { Constants::DATES["SOC_COVID_ELIGIBLE"].to_date + 1.day }

            it "is eligible" do
              rating_request_issue.validate_eligibility!
              expect(rating_request_issue.ineligible_reason).to be_nil
            end
          end

          context "NOD and SOC dates are still ineligible" do
            let(:nod_date) { Constants::DATES["NOD_COVID_ELIGIBLE"].to_date - 1.day }
            let(:soc_date) { Constants::DATES["SOC_COVID_ELIGIBLE"].to_date - 3.days }

            it "is not eligible" do
              rating_request_issue.validate_eligibility!
              expect(rating_request_issue.ineligible_reason).to eq("legacy_appeal_not_eligible")
            end
          end
        end
      end
    end

    context "Issues with decision dates before AMA" do
      let(:receipt_date) { ama_start_date + 5.days }
      let(:profile_date) { ama_start_date - 5.days }

      it "flags nonrating issues before AMA" do
        nonrating_request_issue.decision_date = ama_start_date - 5.days
        nonrating_request_issue.validate_eligibility!

        expect(nonrating_request_issue.ineligible_reason).to eq("before_ama")
      end

      it "flags rating issues before AMA" do
        rating_request_issue.contested_rating_issue_reference_id = "before_ama_ref_id"
        rating_request_issue.validate_eligibility!
        expect(rating_request_issue.ineligible_reason).to eq("before_ama")
      end

      context "decision review is a Supplemental Claim" do
        let(:review) do
          create(
            :supplemental_claim,
            veteran_file_number: veteran.file_number,
            legacy_opt_in_approved: legacy_opt_in_approved
          )
        end

        it "does not apply before AMA checks" do
          nonrating_request_issue.decision_date = ama_start_date - 5.days
          nonrating_request_issue.validate_eligibility!

          expect(nonrating_request_issue.ineligible_reason).to_not eq("before_ama")
          expect(nonrating_request_issue).to be_eligible
        end
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
          rating_request_issue.decision_review.legacy_opt_in_approved = true
          rating_request_issue.vacols_id = "something"
          rating_request_issue.contested_rating_issue_reference_id = "xyz123"

          rating_request_issue.validate_eligibility!

          expect(rating_request_issue.contested_rating_issue).to_not be_nil
          expect(rating_request_issue.ineligible_reason).to be_nil
        end
      end
    end
  end

  context "#close!" do
    subject { rating_request_issue.close!(status: new_status) }
    let(:new_status) { "decided" }

    context "with open request issue" do
      it "sets the specified closed status" do
        expect(rating_request_issue.reload.closed_status).to be_nil
        subject
        expect(rating_request_issue.reload.closed_status).to eq("decided")
      end
    end

    context "with already closed request issue" do
      let(:closed_status) { "withdrawn" }
      let(:closed_at) { 1.day.ago }

      it "refrains from updating" do
        expect(rating_request_issue.reload.closed_status).to eq("withdrawn")
        subject
        expect(rating_request_issue.reload.closed_status).to eq("withdrawn")
      end

      context "when prior status was ineligible" do
        let(:closed_status) { "ineligible" }

        it "leaves as-is when not removing" do
          expect(rating_request_issue.reload.closed_status).to eq("ineligible")
          subject
          expect(rating_request_issue.reload.closed_status).to eq("ineligible")
        end

        context "when updating to `removed`" do
          let(:new_status) { "removed" }

          it "successfully removes the issue" do
            expect(rating_request_issue.reload.closed_status).to eq("ineligible")
            subject
            expect(rating_request_issue.reload.closed_status).to eq("removed")
          end
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
        expect(legacy_issue_optin.reload.rollback_created_at).to be_within(1.second).of Time.zone.now
      end
    end
  end

  context "#withdraw!" do
    let(:withdraw_date) { 2.days.ago.to_date }
    subject { rating_request_issue.withdraw!(withdraw_date) }

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

      it "withdraws issue and does not flag the legacy issue optin for rollback" do
        subject
        expect(rating_request_issue.closed_at).to eq(withdraw_date.to_datetime.utc)
        expect(rating_request_issue.closed_status).to eq("withdrawn")
        expect(legacy_issue_optin.reload.rollback_created_at).to be_nil
      end
    end
  end

  context "#editable?" do
    let(:ep_code) { "030HLRR" }
    let(:end_product_establishment) do
      create(:end_product_establishment,
             :active,
             veteran_file_number: veteran.file_number,
             established_at: receipt_date - 100.days,
             code: ep_code)
    end
    subject { rating_request_issue.editable? }

    context "when rating exists" do
      let(:associated_claims) do
        [{ clm_id: end_product_establishment.reference_id, bnft_clm_tc: ep_code }]
      end

      it { is_expected.to eq(false) }
    end

    context "when rating does not exist" do
      it { is_expected.to eq(true) }
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
          decision_review: rating_request_issue.decision_review,
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
               established_at: receipt_date - 100.days,
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
                rating_promulgation_date: ratings.promulgation_date,
                decision_text: "Left knee granted",
                rating_profile_date: ratings.profile_date,
                decision_review_type: "HigherLevelReview",
                decision_review_id: review.id,
                benefit_type: "compensation",
                end_product_last_action_date: end_product_establishment.result.last_action_date.to_date
              )
              expect(rating_request_issue.processed?).to eq(true)
              expect(rating_request_issue.decision_sync_error).to be_nil
              expect(rating_request_issue.closed_at).to eq(Time.zone.now)
              expect(rating_request_issue.closed_status).to eq("decided")
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
                expect(rating_request_issue.closed_at).to eq(Time.zone.now)
                expect(rating_request_issue.closed_status).to eq("decided")
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
                rating_profile_date: ratings.profile_date,
                rating_promulgation_date: ratings.promulgation_date,
                decision_review_id: review.id,
                benefit_type: "compensation",
                end_product_last_action_date: end_product_establishment.result.last_action_date.to_date
              )
              expect(rating_request_issue.processed?).to eq(true)
              expect(rating_request_issue.closed_at).to eq(Time.zone.now)
              expect(rating_request_issue.closed_status).to eq("decided")
            end
          end
        end

        context "when no associated rating exists" do
          it "raises an error" do
            expect { subject }.to raise_error(RequestIssue::NoAssociatedRating)
          end
        end
      end

      context "with nonrating ep" do
        let(:request_issue) { nonrating_request_issue.tap(&:submit_for_processing!) }

        let(:ep_code) { "030HLRNR" }

        let!(:contention) do
          Generators::Contention.build(
            id: nonrating_contention_reference_id,
            claim_id: end_product_establishment.reference_id,
            disposition: "allowed"
          )
        end

        before do
          # mimic what BGS will do when syncing a nonrating request issue
          allow(Rating).to receive(:fetch_in_range).and_raise(Rating::NilRatingProfileListError)
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
          expect(request_issue.closed_at).to eq(Time.zone.now)
          expect(request_issue.closed_status).to eq("decided")
        end

        context "when there is no disposition" do
          before do
            Fakes::EndProductStore.new.clear!
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
