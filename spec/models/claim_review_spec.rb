# frozen_string_literal: true

describe ClaimReview, :postgres do
  before do
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  def random_ref_id
    SecureRandom.random_number(1_000_000)
  end

  let(:contention_ref_id) { random_ref_id }
  let(:veteran_file_number) { "4205555" }
  let(:veteran_participant_id) { "123456" }
  let(:veteran_date_of_death) { nil }
  let!(:veteran) do
    Generators::Veteran.build(
      file_number: veteran_file_number,
      first_name: "James",
      last_name: "Bond",
      participant_id: veteran_participant_id,
      date_of_death: veteran_date_of_death
    )
  end

  let(:receipt_date) { ama_test_start_date + 1 }
  let(:informal_conference) { nil }
  let(:same_office) { nil }
  let(:benefit_type) { "compensation" }
  let(:ineligible_reason) { nil }
  let(:rating_profile_date) { Date.new(2018, 4, 30) }
  let(:vacols_id) { nil }
  let(:vacols_sequence_id) { nil }
  let(:vacols_case) { create(:case, case_issues: [create(:case_issue)]) }
  let(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

  let(:rating_request_issue) do
    build(
      :request_issue,
      decision_review: claim_review,
      contested_rating_issue_reference_id: "reference-id",
      contested_rating_issue_profile_date: rating_profile_date,
      contested_issue_description: "decision text",
      benefit_type: benefit_type,
      ineligible_reason: ineligible_reason,
      vacols_id: vacols_id,
      vacols_sequence_id: vacols_sequence_id
    )
  end

  let(:second_rating_request_issue) do
    build(
      :request_issue,
      decision_review: claim_review,
      contested_rating_issue_reference_id: "reference-id2",
      contested_rating_issue_profile_date: rating_profile_date,
      contested_issue_description: "another decision text",
      benefit_type: benefit_type
    )
  end

  let(:non_rating_request_issue) do
    build(
      :request_issue,
      decision_review: claim_review,
      nonrating_issue_description: "Issue text",
      nonrating_issue_category: "surgery",
      decision_date: 4.days.ago.to_date,
      benefit_type: benefit_type,
      ineligible_reason: ineligible_reason
    )
  end

  let(:second_non_rating_request_issue) do
    build(
      :request_issue,
      decision_review: claim_review,
      nonrating_issue_description: "some other issue",
      nonrating_issue_category: "something",
      decision_date: 3.days.ago.to_date,
      benefit_type: benefit_type
    )
  end

  let(:rating_request_issue_with_rating_decision) do
    create(
      :request_issue,
      decision_review: claim_review,
      contested_rating_decision_reference_id: "rating-decision-diagnostic-id",
      contested_rating_issue_profile_date: rating_profile_date,
      contested_issue_description: "foobar was denied."
    )
  end

  let(:claim_review) do
    build(
      :higher_level_review,
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      informal_conference: informal_conference,
      same_office: same_office,
      benefit_type: benefit_type
    )
  end

  let!(:supplemental_claim) do
    create(
      :supplemental_claim,
      veteran_file_number: veteran_file_number
    )
  end

  let!(:claimant) do
    create(
      :claimant,
      decision_review: claim_review,
      participant_id: veteran_participant_id,
      payee_code: "00"
    )
  end

  describe "#cancel_establishment!" do
    let(:claim_review) do
      create(
        :higher_level_review,
        receipt_date: receipt_date,
        establishment_attempted_at: (ClaimReview.processing_retry_interval_hours - 1).hours.ago,
        establishment_error: "oops!"
      )
    end

    subject { claim_review.cancel_establishment! }

    it "sets async canceled_at and closes all request_issues" do
      request_issue = rating_request_issue.tap(&:save!)

      expect(request_issue).to_not be_closed

      subject

      claim_review.reload

      expect(claim_review).to be_canceled
      expect(claim_review.establishment_error).to eq("oops!")
      expect(request_issue.reload).to be_closed
    end
  end

  let(:vbms_error) do
    VBMS::HTTPError.new("500", "More EPs more problems")
  end

  context "async logic scopes" do
    let!(:claim_review_requiring_processing) do
      create(:higher_level_review, :requires_processing, receipt_date: receipt_date)
    end

    let!(:claim_review_processed) do
      create(:higher_level_review, receipt_date: receipt_date).tap(&:processed!)
    end

    let!(:claim_review_recently_attempted) do
      create(
        :higher_level_review,
        receipt_date: receipt_date,
        establishment_attempted_at: (ClaimReview.processing_retry_interval_hours - 1).hours.ago
      )
    end

    let!(:claim_review_attempts_ended) do
      create(
        :higher_level_review,
        receipt_date: receipt_date,
        establishment_last_submitted_at: (ClaimReview::REQUIRES_PROCESSING_WINDOW_DAYS + 5).days.ago,
        establishment_attempted_at: (ClaimReview::REQUIRES_PROCESSING_WINDOW_DAYS + 1).days.ago
      )
    end

    let!(:claim_review_canceled) do
      create(
        :higher_level_review,
        receipt_date: receipt_date,
        establishment_canceled_at: 2.days.ago
      )
    end

    context ".unexpired" do
      it "matches reviews still inside the processing window" do
        expect(HigherLevelReview.unexpired).to eq([claim_review_requiring_processing])
      end
    end

    context ".canceled" do
      it "only returns canceled jobs" do
        expect(HigherLevelReview.canceled).to eq([claim_review_canceled])
      end
    end

    context ".processable" do
      it "matches reviews eligible for processing" do
        expect(HigherLevelReview.processable).to match_array(
          [claim_review_requiring_processing, claim_review_attempts_ended]
        )
      end
    end

    context ".attemptable" do
      it "matches reviews that could be attempted" do
        expect(HigherLevelReview.attemptable).not_to include(claim_review_recently_attempted)
        expect(HigherLevelReview.attemptable).not_to include(claim_review_canceled)
      end
    end

    context ".requires_processing" do
      it "matches reviews that must still be processed" do
        expect(HigherLevelReview.requires_processing).to eq([claim_review_requiring_processing])
      end
    end

    context ".expired_without_processing" do
      it "matches reviews unfinished but outside the retry window" do
        expect(HigherLevelReview.expired_without_processing).to eq([claim_review_attempts_ended])
      end
    end
  end

  context "#active?" do
    subject { claim_review.active? }

    context "when it is processed in Caseflow and has completed tasks" do
      let(:benefit_type) { "nca" }
      let!(:completed_task) { create(:task, :completed, appeal: claim_review) }

      it { is_expected.to be false }

      context "when there are any incomplete tasks" do
        let!(:in_progress_task) { create(:task, :in_progress, appeal: claim_review) }

        it "returns true" do
          expect(subject).to eq(true)
        end
      end
    end

    context "when it is processed in VBMS and has a cleared EPE" do
      let(:benefit_type) { "compensation" }
      let!(:cleared_epe) do
        create(:end_product_establishment,
               :cleared,
               code: rating_request_issue.end_product_code,
               source: claim_review,
               veteran_file_number: claim_review.veteran.file_number)
      end

      it { is_expected.to be false }

      context "when there is at least one active end product establishment" do
        let!(:active_epe) do
          create(:end_product_establishment,
                 :active,
                 code: rating_request_issue.end_product_code,
                 source: claim_review,
                 veteran_file_number: claim_review.veteran.file_number)
        end

        it { is_expected.to be true }
      end
    end
  end

  context "#timely_issue?" do
    before do
      Timecop.freeze(Time.utc(2019, 4, 24, 12, 0, 0))
    end

    subject { create(:higher_level_review, receipt_date: Time.zone.today) }

    context "decided in the last year" do
      it "considers it timely" do
        expect(subject.timely_issue?(Time.zone.today)).to eq(true)
      end
    end

    context "decided more than a year ago" do
      it "considers it untimely" do
        expect(subject.timely_issue?(Time.zone.today - 400)).to eq(false)
      end
    end
  end

  context "#add_user_to_business_line!" do
    subject { claim_review.add_user_to_business_line! }

    before { RequestStore[:current_user] = user }
    let(:user) { Generators::User.build }

    context "when the intake is a" do
      let(:benefit_type) { "compensation" }

      it { is_expected.to be_nil }
    end

    context "when the intake is not compensation or pension" do
      let(:benefit_type) { "education" }

      context "when the user is already on the organization" do
        let!(:existing_record) { claim_review.business_line.add_user(user) }

        it "returns the existing record" do
          expect(subject).to eq(existing_record)
        end
      end

      context "when the user isn't added to the organization" do
        it "adds the user to the organization" do
          expect(OrganizationsUser.existing_record(user, claim_review.business_line)).to be_nil
          subject
          expect(OrganizationsUser.find_by(user: user, organization: claim_review.business_line)).to_not be_nil
        end
      end
    end
  end

  context "#serialized_ratings" do
    let(:ratings) do
      [
        Generators::PromulgatedRating.build(promulgation_date: Time.zone.today - 30),
        Generators::PromulgatedRating.build(promulgation_date: Time.zone.today - 60, issues: [], decisions: decisions),
        Generators::PromulgatedRating.build(promulgation_date: Time.zone.today - 400)
      ]
    end

    let(:decisions) do
      [
        { decision_text: "not service connected for bad knee" }
      ]
    end

    before do
      FeatureToggle.enable!(:contestable_rating_decisions)
      allow(subject.veteran).to receive(:ratings).and_return(ratings)
    end

    after do
      FeatureToggle.disable!(:contestable_rating_decisions)
    end

    subject do
      create(:higher_level_review, veteran_file_number: veteran_file_number, receipt_date: Time.zone.today)
    end

    it "filters out ratings with zero decisions and zero issues" do
      expect(subject.serialized_ratings.count).to eq(3)
    end

    it "calculates timely flag" do
      serialized_ratings = subject.serialized_ratings

      expect(serialized_ratings.first[:issues]).to include(hash_including(timely: true), hash_including(timely: true))
      expect(serialized_ratings.last[:issues]).to include(hash_including(timely: false), hash_including(timely: false))
    end

    context "benefit type is not compensation or pension" do
      before do
        subject.update!(benefit_type: "education")
      end

      it "returns nil" do
        expect(subject.serialized_ratings).to be_nil
      end
    end
  end

  context "#processed_in_caseflow?" do
    let(:claim_review) { create(:higher_level_review, benefit_type: benefit_type) }

    subject { claim_review.processed_in_caseflow? }

    context "when benefit_type is compensation" do
      let(:benefit_type) { "compensation" }

      it { is_expected.to be_falsey }
    end

    context "when benefit_type is pension" do
      let(:benefit_type) { "pension" }

      it { is_expected.to be_falsey }
    end

    context "when benefit_type is something else" do
      let(:benefit_type) { "foobar" }

      it { is_expected.to be_truthy }
    end
  end

  context "#create_business_line_tasks!" do
    subject { claim_review.create_business_line_tasks! }
    let!(:request_issue) { create(:request_issue, decision_review: claim_review) }

    context "when processed in caseflow" do
      let(:benefit_type) { "vha" }

      it "creates a decision review task" do
        expect { subject }.to change(DecisionReviewTask, :count).by(1)

        expect(DecisionReviewTask.last).to have_attributes(
          appeal: claim_review,
          assigned_at: Time.zone.now,
          assigned_to: BusinessLine.find_by(url: "vha")
        )
      end

      context "when a task already exists" do
        before do
          claim_review.create_business_line_tasks!
          claim_review.reload
        end

        it "does nothing" do
          expect { subject }.to_not change(DecisionReviewTask, :count)
        end
      end

      context "when the review only has ineligible issues" do
        let!(:request_issue) { create(:request_issue, :ineligible, decision_review: claim_review) }

        it "does nothing" do
          expect { subject }.to_not change(DecisionReviewTask, :count)
        end
      end
    end

    context "when processed in VBMS" do
      let(:benefit_type) { "compensation" }

      it "does nothing" do
        expect { subject }.to_not change(DecisionReviewTask, :count)
      end
    end
  end

  describe "#create_issues!" do
    before { claim_review.save! }
    subject { claim_review.create_issues!(issues) }

    context "when there's just one issue" do
      let(:issues) { [rating_request_issue] }

      it "creates the issue and assigns a end product establishment" do
        subject

        expect(rating_request_issue.reload.end_product_establishment).to have_attributes(code: "030HLRR")
        expect(rating_request_issue.legacy_issues).to be_empty
      end

      context "when there is an associated legacy issue" do
        let(:vacols_id) { legacy_appeal.vacols_id }
        let(:vacols_sequence_id) { legacy_appeal.issues.first.vacols_sequence_id }

        context "when the veteran did not opt in their legacy issues" do
          let(:ineligible_reason) { "legacy_issue_not_withdrawn" }

          it "creates a legacy issue, but no optin" do
            subject

            expect(rating_request_issue.legacy_issues.count).to eq 1
            expect(rating_request_issue.legacy_issue_optin).to be_nil
          end
        end

        context "when legacy opt in is approved by the veteran" do
          let(:ineligible_reason) { nil }

          it "creates a legacy issue and an associated opt in" do
            subject

            expect(rating_request_issue.legacy_issue_optin.legacy_issue).to eq(rating_request_issue.legacy_issues.first)
          end
        end
      end
    end

    context "when there's more than one issue" do
      let(:issues) { [rating_request_issue, non_rating_request_issue, rating_request_issue_with_rating_decision] }

      context "when they're all ineligible" do
        let(:ineligible_reason) { "duplicate_of_rating_issue_in_active_review" }

        it "does not create end product establishments" do
          subject

          expect(rating_request_issue.reload.end_product_establishment).to be_nil
          expect(non_rating_request_issue.reload.end_product_establishment).to be_nil
        end
      end

      it "creates the issues and assigns end product establishments to them" do
        subject

        expect(rating_request_issue.reload.end_product_establishment).to have_attributes(code: "030HLRR")
        expect(non_rating_request_issue.reload.end_product_establishment).to have_attributes(code: "030HLRNR")
        expect(rating_request_issue_with_rating_decision.reload.end_product_establishment).to \
          have_attributes(code: "030HLRR")
      end

      context "when the benefit type is pension" do
        let(:benefit_type) { "pension" }

        it "creates issues and assigns pension end product codes to them" do
          subject

          expect(rating_request_issue.reload.end_product_establishment).to have_attributes(code: "030HLRRPMC")
          expect(non_rating_request_issue.reload.end_product_establishment).to have_attributes(code: "030HLRNRPMC")
          expect(rating_request_issue_with_rating_decision.reload.end_product_establishment).to \
            have_attributes(code: "030HLRRPMC")
        end
      end

      context "when EP code depends on all issues being present" do
        before { FeatureToggle.enable!(:itf_supplemental_claims) }
        after { FeatureToggle.disable!(:itf_supplemental_claims) }

        let(:claim_review) do
          build(
            :supplemental_claim,
            veteran_file_number: veteran_file_number,
            receipt_date: receipt_date,
            benefit_type: benefit_type
          )
        end
        let(:issues) do
          [Time.zone.yesterday, 2.years.ago].map do |decision_date|
            # use .new to ensure issues aren't all saved to DB initially
            RequestIssue.new(
              decision_review: claim_review,
              benefit_type: benefit_type,
              contested_rating_issue_reference_id: "reference-id",
              decision_date: decision_date
            )
          end
        end

        it "creates issues and assigns the correct EP code" do
          subject

          expect(issues.map(&:reload).map(&:end_product_establishment).uniq.map(&:code)).to eq(["040SCRGTY"])
        end
      end
    end

    context "when there is a canceled end product establishment" do
      let!(:canceled_epe) do
        create(:end_product_establishment,
               :canceled,
               code: rating_request_issue.end_product_code,
               source: claim_review,
               veteran_file_number: claim_review.veteran.file_number)
      end

      let(:issues) { [non_rating_request_issue, rating_request_issue] }

      it "does not attempt to re-use the canceled EPE" do
        subject

        expect(claim_review.reload.end_product_establishments.count).to eq(3)
      end
    end

    context "when the issue is a correction to a dta decision" do
      before do
        allow(RequestIssueCorrectionCleaner).to receive(:new).with(correction_request_issue).and_call_original
        dr_remanded.create_remand_supplemental_claims!
      end

      let(:claim_review) do
        create(
          :supplemental_claim,
          veteran_file_number: veteran_file_number,
          benefit_type: benefit_type,
          decision_review_remanded: dr_remanded
        )
      end
      let(:dr_remanded) do
        create(
          :higher_level_review,
          veteran_file_number: veteran_file_number,
          benefit_type: benefit_type,
          number_of_claimants: 1
        )
      end
      let!(:remand_decision) { create(:decision_issue, decision_review: dr_remanded, disposition: "DTA Error") }
      let(:correction_request_issue) do
        build(
          :request_issue,
          decision_review: claim_review,
          correction_type: "control",
          contested_decision_issue: remand_decision
        )
      end
      let(:issues) { [correction_request_issue] }

      it "removes the dta request issue" do
        expect_any_instance_of(RequestIssueCorrectionCleaner).to receive(:remove_dta_request_issue!)

        subject
      end
    end
  end

  context "#establish!" do
    let!(:user) do
      User.create(
        station_id: 1,
        css_id: "test_user",
        full_name: "Test User"
      )
    end

    let!(:intake) do
      Intake.create(
        user_id: user.id,
        detail: claim_review,
        veteran_file_number: veteran.file_number,
        started_at: Time.zone.now,
        completed_at: Time.zone.now,
        completion_status: "success",
        type: "HigherLevelReviewIntake"
      )
    end

    before do
      claim_review.save!
      claim_review.create_issues!(issues)

      allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
      allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
    end

    subject { claim_review.establish! }

    context "when there is just one end_product_establishment" do
      let(:issues) { [rating_request_issue, second_rating_request_issue, rating_request_issue_with_rating_decision] }

      it "establishes the claim and creates the contentions in VBMS" do
        subject

        expect(Fakes::VBMSService).to have_received(:establish_claim!).once.with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: user.station_id,
            date: claim_review.receipt_date.to_date,
            end_product_modifier: "030",
            end_product_label: "Higher-Level Review Rating",
            end_product_code: "030HLRR",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false,
            claimant_participant_id: veteran_participant_id,
            limited_poa_code: nil,
            limited_poa_access: nil,
            status_type_code: "PEND"
          },
          veteran_hash: veteran.to_vbms_hash,
          user: user
        )

        expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
          veteran_file_number: veteran_file_number,
          claim_id: claim_review.end_product_establishments.last.reference_id,
          contentions: array_including(
            { description: "another decision text",
              contention_type: Constants.CONTENTION_TYPES.higher_level_review },
            { description: "foobar was denied.",
              contention_type: Constants.CONTENTION_TYPES.higher_level_review },
            description: "decision text",
            contention_type: Constants.CONTENTION_TYPES.higher_level_review
          ),
          user: user,
          claim_date: claim_review.receipt_date.to_date
        )

        expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).once.with(
          claim_id: claim_review.end_product_establishments.last.reference_id,
          rating_issue_contention_map: {
            "reference-id" => rating_request_issue.reload.contention_reference_id,
            "reference-id2" => second_rating_request_issue.reload.contention_reference_id
          }
        )

        expect(claim_review.end_product_establishments.first).to be_committed
        expect(rating_request_issue.rating_issue_associated_at).to eq(Time.zone.now)
        expect(second_rating_request_issue.rating_issue_associated_at).to eq(Time.zone.now)
        expect(rating_request_issue_with_rating_decision.reload.rating_issue_associated_at).to be_nil
      end

      context "when associate rating request issues fails" do
        before do
          allow(VBMSService).to receive(:associate_rating_request_issues!).and_raise(vbms_error)
        end

        it "does not commit the end product establishment" do
          expect { subject }.to raise_error(vbms_error)
          expect(claim_review.end_product_establishments.first).to_not be_committed
          expect(rating_request_issue.rating_issue_associated_at).to be_nil
          expect(second_rating_request_issue.rating_issue_associated_at).to be_nil
        end
      end

      context "when there are no rating issues" do
        let(:issues) { [non_rating_request_issue] }

        it "does not associate_rating_request_issues" do
          subject
          expect(Fakes::VBMSService).to_not have_received(:associate_rating_request_issues!)
          expect(non_rating_request_issue.rating_issue_associated_at).to be_nil
        end
      end

      context "when the end product was already established" do
        before { claim_review.end_product_establishments.first.update!(reference_id: "REF_ID") }

        it "doesn't establish it again in VBMS" do
          subject

          expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
          expect(Fakes::VBMSService).to have_received(:create_contentions!)
        end

        context "when the end product is no longer active" do
          before do
            Fakes::BGSService.manage_claimant_letter_v2_requests = nil
            Fakes::BGSService.generate_tracked_items_requests = nil
            claim_review.end_product_establishments.first.update!(synced_status: "CLR")
          end

          let(:informal_conference) { true }

          it "does not attempt subsequent actions on the end product and completes the establishment job" do
            subject

            expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
            expect(Fakes::VBMSService).to_not have_received(:create_contentions!)
            expect(Fakes::VBMSService).to_not have_received(:associate_rating_request_issues!)
            expect(Fakes::BGSService.manage_claimant_letter_v2_requests).to be_nil
            expect(Fakes::BGSService.generate_tracked_items_requests).to be_nil
            expect(claim_review.establishment_processed_at).to eq Time.zone.now
            expect(claim_review.establishment_error).to be_nil
          end
        end

        context "when some of the contentions have already been saved" do
          let(:one_day_ago) { 1.day.ago }

          before do
            rating_request_issue.update!(
              contention_reference_id: contention_ref_id,
              rating_issue_associated_at: one_day_ago
            )
          end

          it "doesn't create them in VBMS, and re-sends the new contention map" do
            subject

            expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
              veteran_file_number: veteran_file_number,
              claim_id: claim_review.end_product_establishments.last.reference_id,
              contentions: containing_exactly(
                { description: "another decision text",
                  contention_type: Constants.CONTENTION_TYPES.higher_level_review },
                description: "foobar was denied.",
                contention_type: Constants.CONTENTION_TYPES.higher_level_review
              ),
              user: user,
              claim_date: claim_review.receipt_date.to_date
            )

            expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).once.with(
              claim_id: claim_review.end_product_establishments.last.reference_id,
              rating_issue_contention_map: {
                "reference-id" => rating_request_issue.reload.contention_reference_id,
                "reference-id2" => second_rating_request_issue.reload.contention_reference_id
              }
            )

            expect(rating_request_issue.rating_issue_associated_at).to eq(Time.zone.now)
            expect(second_rating_request_issue.rating_issue_associated_at).to eq(Time.zone.now)
          end
        end

        context "when all the contentions have already been saved" do
          before do
            rating_request_issue.update!(
              contention_reference_id: contention_ref_id, rating_issue_associated_at: Time.zone.now
            )
            second_rating_request_issue.update!(
              contention_reference_id: random_ref_id, rating_issue_associated_at: Time.zone.now
            )
            rating_request_issue_with_rating_decision.update!(contention_reference_id: "rating-decision-contention")
          end

          it "doesn't create them in VBMS" do
            subject

            expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
            expect(Fakes::VBMSService).to_not have_received(:create_contentions!)
            expect(Fakes::VBMSService).to_not have_received(:associate_rating_request_issues!)
          end
        end

        context "when informal conference already has a tracked item" do
          before do
            claim_review.end_product_establishments.first.update!(doc_reference_id: "DOC_REF_ID")
            claim_review.end_product_establishments.first.update!(
              development_item_reference_id: "dev_item_ref_id"
            )

            # Cleaning Fakes:BGSService because it seems to persist between tests
            Fakes::BGSService.manage_claimant_letter_v2_requests = nil
            Fakes::BGSService.generate_tracked_items_requests = nil
          end

          it "doesn't create it in BGS" do
            subject

            expect(Fakes::BGSService.manage_claimant_letter_v2_requests).to be_nil
            expect(Fakes::BGSService.generate_tracked_items_requests).to be_nil
          end
        end
      end

      context "when called multiple times" do
        it "remains idempotent despite multiple VBMS failures" do
          raise_error_on_end_product_establishment_establish_claim

          expect(Fakes::VBMSService).to receive(:establish_claim!).once
          expect { subject }.to raise_error(vbms_error)
          expect(claim_review.establishment_processed_at).to be_nil

          allow_end_product_establishment_establish_claim
          raise_error_on_create_contentions

          expect(Fakes::VBMSService).to receive(:establish_claim!).once
          expect(Fakes::VBMSService).to receive(:create_contentions!).once
          expect { subject }.to raise_error(vbms_error)
          expect(claim_review.establishment_processed_at).to be_nil
          expect(epe.reference_id).to_not be_nil
          expect(claim_contentions_for_all_issues_on_epe.count).to eq(0)

          allow_create_contentions
          raise_error_on_associate_rating_request_issues

          expect(Fakes::VBMSService).to_not receive(:establish_claim!)
          expect(Fakes::VBMSService).to receive(:create_contentions!).once
          expect(Fakes::VBMSService).to receive(:associate_rating_request_issues!).once
          expect { subject }.to raise_error(vbms_error)
          expect(claim_review.establishment_processed_at).to be_nil

          epe_contentions = claim_contentions_for_all_issues_on_epe
          expect(epe_contentions.count).to eq(3)
          expect(epe_contentions.where.not(rating_issue_associated_at: nil).count).to eq(0)

          allow_associate_rating_request_issues

          expect(Fakes::VBMSService).to_not receive(:establish_claim!)
          expect(Fakes::VBMSService).to_not receive(:create_contentions!)
          expect(Fakes::VBMSService).to receive(:associate_rating_request_issues!).once
          subject
          expect(claim_review.establishment_processed_at).to eq(Time.zone.now)

          expect(Fakes::VBMSService).to_not receive(:establish_claim!)
          expect(Fakes::VBMSService).to_not receive(:create_contentions!)
          expect(Fakes::VBMSService).to_not receive(:associate_rating_request_issues!)
          subject
        end

        def raise_error_on_end_product_establishment_establish_claim
          allow(Fakes::VBMSService).to receive(:establish_claim!).and_raise(vbms_error)
        end

        def allow_end_product_establishment_establish_claim
          allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
        end

        def raise_error_on_create_contentions
          allow(Fakes::VBMSService).to receive(:create_contentions!).and_raise(vbms_error)
        end

        def allow_create_contentions
          allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
        end

        def raise_error_on_associate_rating_request_issues
          allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_raise(vbms_error)
        end

        def allow_associate_rating_request_issues
          allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
        end

        def claim_contentions_for_all_issues_on_epe
          claim_review.request_issues.where(end_product_establishment: epe).where.not(contention_reference_id: nil)
        end

        def epe
          claim_review.end_product_establishments.first
        end
      end

      context "when informal conference is true" do
        let(:informal_conference) { true }

        it "generates claimant letter and tracked item" do
          subject
          epe = claim_review.end_product_establishments.last
          expect(epe).to have_attributes(
            doc_reference_id: "doc_reference_id_result",
            development_item_reference_id: "development_item_reference_id_result"
          )

          letter_request = Fakes::BGSService.manage_claimant_letter_v2_requests
          expect(letter_request[epe.reference_id]).to eq(
            program_type_cd: "CPL", claimant_participant_id: veteran_participant_id
          )

          tracked_item_request = Fakes::BGSService.generate_tracked_items_requests
          expect(tracked_item_request[epe.reference_id]).to be(true)
        end

        context "when veteran is deceased" do
          let(:veteran_date_of_death) { 1.year.ago }

          it "sets program_type_cd to CPD" do
            subject
            epe = claim_review.end_product_establishments.last

            letter_request = Fakes::BGSService.manage_claimant_letter_v2_requests
            expect(letter_request[epe.reference_id]).to eq(
              program_type_cd: "CPD", claimant_participant_id: veteran_participant_id
            )
          end
        end
      end
    end

    context "when there are more than one end product establishments" do
      let(:issues) { [non_rating_request_issue, rating_request_issue] }

      it "establishes the claim and creates the contentions in VBMS for each one" do
        subject

        expect(claim_review.end_product_establishments.count).to eq(2)

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: user.station_id,
            date: claim_review.receipt_date.to_date,
            end_product_modifier: "030",
            end_product_label: "Higher-Level Review Rating",
            end_product_code: "030HLRR",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false,
            claimant_participant_id: veteran_participant_id,
            limited_poa_code: nil,
            limited_poa_access: nil,
            status_type_code: "PEND"
          },
          veteran_hash: veteran.to_vbms_hash,
          user: user
        )

        expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
          veteran_file_number: veteran_file_number,
          claim_id: claim_review.end_product_establishments.find_by(code: "030HLRR").reference_id,
          contentions: array_including(description: "decision text",
                                       contention_type: Constants.CONTENTION_TYPES.higher_level_review),
          user: user,
          claim_date: claim_review.receipt_date.to_date
        )

        expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).once.with(
          claim_id: claim_review.end_product_establishments.find_by(code: "030HLRR").reference_id,
          rating_issue_contention_map: {
            "reference-id" => rating_request_issue.reload.contention_reference_id
          }
        )

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: user.station_id,
            date: claim_review.receipt_date.to_date,
            end_product_modifier: "031", # Important that the modifier increments for the second EP
            end_product_label: "Higher-Level Review Nonrating",
            end_product_code: "030HLRNR",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false,
            claimant_participant_id: veteran_participant_id,
            limited_poa_code: nil,
            limited_poa_access: nil,
            status_type_code: "PEND"
          },
          veteran_hash: veteran.to_vbms_hash,
          user: user
        )

        expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
          veteran_file_number: veteran_file_number,
          claim_id: claim_review.end_product_establishments.find_by(code: "030HLRNR").reference_id,
          contentions: array_including(description: "surgery - Issue text",
                                       contention_type: Constants.CONTENTION_TYPES.higher_level_review),
          user: user,
          claim_date: claim_review.receipt_date.to_date
        )

        expect(claim_review.end_product_establishments.first).to be_committed
        expect(claim_review.end_product_establishments.last).to be_committed
        expect(rating_request_issue.rating_issue_associated_at).to eq(Time.zone.now)
        expect(non_rating_request_issue.rating_issue_associated_at).to be_nil
      end
    end
  end

  describe ".find_by_uuid_or_reference_id!" do
    let(:hlr) { create(:higher_level_review, :with_end_product_establishment).reload }

    it "finds by UUID" do
      expect(HigherLevelReview.find_by_uuid_or_reference_id!(hlr.uuid)).to eq(hlr)
    end

    it "finds by EPE reference_id" do
      hlr.end_product_establishments.first.update!(reference_id: "abc123")

      expect(HigherLevelReview.find_by_uuid_or_reference_id!("abc123")).to eq(hlr)
    end
  end

  describe "#find_all_visible_by_file_number" do
    let!(:removed_hlr) { create(:higher_level_review, veteran_file_number: veteran_file_number) }
    let!(:removed_sc) { create(:supplemental_claim, veteran_file_number: veteran_file_number) }
    let!(:removed_hlr_issue) { create(:request_issue, :removed, decision_review: removed_hlr) }
    let!(:removed_sc_issue) { create(:request_issue, :removed, decision_review: removed_sc) }

    it "finds higher level reviews and supplemental claims" do
      expect(ClaimReview.find_all_visible_by_file_number(veteran_file_number).length).to eq(2)
    end
  end

  describe "#search_table_ui_hash" do
    let!(:appeal) { create(:appeal) }
    let!(:sc) do
      create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number, number_of_claimants: 2)
    end

    it "returns review type" do
      expect([*sc].map(&:search_table_ui_hash)).to include(hash_including(
                                                             review_type: "supplemental_claim"
                                                           ))
    end

    it "removes duplicate claimant names, if they exist" do
      expect([*sc].map(&:search_table_ui_hash).first[:claimant_names].length).to eq(1)
    end
  end

  describe "#search_table_statuses" do
    let(:claim_review) { create(:higher_level_review, benefit_type: benefit_type) }
    subject { claim_review.search_table_statuses }

    context "claim says 'Processed in Caseflow' if it is processed in Caseflow" do
      let(:benefit_type) { "foobar" }
      let!(:expected_result) do
        [{
          ep_code: "Processed in Caseflow",
          ep_status: ""
        }]
      end

      it { is_expected.to eq expected_result }
    end

    context "if it is not processed in Caseflow and there are no end products" do
      let(:benefit_type) { "compensation" }

      it { is_expected.to eq [] }
    end

    context "if it is not processed in Caseflow and there are end products" do
      let(:benefit_type) { "compensation" }
      let(:end_product_establishment) { create(:end_product_establishment, source: claim_review) }

      before do
        end_product_establishment.commit!
      end

      it { is_expected.to have_attributes(length: 1) }
    end
  end

  describe "#claim_veteran" do
    let!(:veteran) { create(:veteran) }
    let!(:hlr) { create(:higher_level_review, veteran_file_number: veteran.file_number) }

    it "returns the veteran" do
      expect(hlr.claim_veteran).to eq(veteran)
    end
  end

  describe "#sync_end_product_establishments!" do
    let!(:veteran) { create(:veteran) }
    let!(:claim_review) { create(:higher_level_review, veteran_file_number: veteran.file_number) }
    let!(:end_product_establishment) do
      create(:end_product_establishment, source: claim_review, veteran_file_number: veteran.file_number)
    end

    before do
      claim_review.create_issues!([rating_request_issue])
      claim_review.establish!
    end

    it "syncs all EPEs" do
      expect(claim_review.end_product_establishments.first.last_synced_at).to be_nil
      claim_review.reload.sync_end_product_establishments!
      expect(claim_review.end_product_establishments.first.last_synced_at).to_not be_nil
    end
  end
end
