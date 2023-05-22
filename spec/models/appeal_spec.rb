# frozen_string_literal: true

require_relative "appeal_shared_examples"

describe Appeal, :all_dbs do
  include IntakeHelpers

  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  let!(:appeal) { create(:appeal) } # must be *after* Timecop.freeze

  context "#create_stream" do
    let(:stream_type) { Constants.AMA_STREAM_TYPES.vacate }
    let!(:appeal) { create(:appeal, number_of_claimants: 1) }

    subject { appeal.create_stream(stream_type) }

    it "creates a new appeal stream with data from the original appeal" do
      expect(subject).to have_attributes(
        receipt_date: appeal.receipt_date,
        veteran_file_number: appeal.veteran_file_number,
        legacy_opt_in_approved: appeal.legacy_opt_in_approved,
        veteran_is_not_claimant: appeal.veteran_is_not_claimant,
        stream_docket_number: appeal.docket_number,
        stream_type: stream_type,
        established_at: Time.zone.now
      )
      expect(subject.reload.claimant).to have_attributes(
        participant_id: appeal.claimant.participant_id,
        type: appeal.claimant.type
      )
    end

    context "for de_novo appeal stream" do
      let(:stream_type) { Constants.AMA_STREAM_TYPES.de_novo }

      it "creates a de_novo appeal stream with data from the original appeal" do
        expect(subject).to have_attributes(
          receipt_date: appeal.receipt_date,
          veteran_file_number: appeal.veteran_file_number,
          legacy_opt_in_approved: appeal.legacy_opt_in_approved,
          veteran_is_not_claimant: appeal.veteran_is_not_claimant,
          stream_docket_number: appeal.docket_number,
          stream_type: stream_type,
          established_at: Time.zone.now
        )
        expect(Appeal.de_novo.find_by(stream_docket_number: appeal.docket_number)).to_not be_nil
        expect(subject.reload.claimant.participant_id).to eq(appeal.claimant.participant_id)
      end
    end
  end

  context "includes PrintsTaskTree concern" do
    context "#structure" do
      let!(:root_task) { create(:root_task, appeal: appeal) }

      subject { appeal.structure(:id) }

      it "returns the task structure" do
        expect_any_instance_of(RootTask).to receive(:structure).with(:id)
        expect(subject.key?(:"Appeal #{appeal.id} [id]")).to be_truthy
      end
    end

    context "#structure_as_json" do
      let!(:root_task) { create(:root_task, appeal: appeal) }

      subject { appeal.structure_as_json(:id) }

      it "returns the task tree as a hash" do
        expect(subject).to eq(Appeal: { id: appeal.id, tasks: [{ RootTask: { id: root_task.id, tasks: [] } }] })
      end
    end
  end

  context "active appeals" do
    let!(:active_appeal) { create(:appeal, :with_post_intake_tasks) }
    let!(:inactive_appeal) { create(:appeal, :outcoded) }

    subject { Appeal.active }
    it "returns only active appeals" do
      expect(subject).to include active_appeal
      expect(subject).to_not include inactive_appeal
    end
  end

  context "#create_business_line_tasks!" do
    let(:request_issues) do
      [
        create(:request_issue, benefit_type: "education"),
        create(:request_issue, benefit_type: "education"),
        create(:request_issue, benefit_type: "nca")
      ]
    end
    let(:appeal) { create(:appeal, request_issues: request_issues) }

    subject { appeal.create_business_line_tasks! }

    it "creates one VeteranRecordRequest task per business line" do
      expect(VeteranRecordRequest).to receive(:create!).twice

      subject
    end

    context "when the appeal has no active issues" do
      let(:request_issues) do
        [
          create(:request_issue, :ineligible, benefit_type: "education"),
          create(:request_issue, :ineligible, benefit_type: "nca")
        ]
      end

      it "does not create business line tasks" do
        expect(VeteranRecordRequest).to_not receive(:create!)

        subject
      end
    end

    context "when the appeal has only vha issues" do
      let(:request_issues) do
        [
          create(:request_issue, benefit_type: "vha", is_predocket_needed: true)
        ]
      end

      it "does not create business line tasks" do
        expect(VeteranRecordRequest).to_not receive(:create!)

        subject
      end
    end

    context "when the appeal has vha and non-vha issues" do
      let(:request_issues) do
        [
          create(:request_issue, benefit_type: "vha", is_predocket_needed: true),
          create(:request_issue, benefit_type: "nca")
        ]
      end

      it "does create business line tasks" do
        expect(VeteranRecordRequest).to receive(:create!)

        subject
      end
    end

    context "when the appeal has a pre-docket education issue" do
      let(:request_issues) do
        [
          create(:request_issue, benefit_type: "education", is_predocket_needed: true)
        ]
      end

      before do
        FeatureToggle.enable!(:edu_predocket_appeals)
      end

      after do
        FeatureToggle.disable!(:edu_predocket_appeals)
      end

      it "does not create business line tasks" do
        expect(VeteranRecordRequest).to_not receive(:create!)

        subject
      end
    end

    context "when the appeal has a non pre-docket education issue" do
      let(:request_issues) do
        [
          create(:request_issue, benefit_type: "education", is_predocket_needed: false)
        ]
      end

      before do
        FeatureToggle.enable!(:edu_predocket_appeals)
      end

      after do
        FeatureToggle.disable!(:edu_predocket_appeals)
      end

      it "does create business line tasks" do
        expect(VeteranRecordRequest).to receive(:create!)

        subject
      end
    end
  end

  context "#create_issues!" do
    subject { appeal.create_issues!(issues) }

    let(:issues) { [request_issue] }
    let(:request_issue) do
      create(
        :request_issue,
        ineligible_reason: ineligible_reason,
        vacols_id: vacols_id,
        vacols_sequence_id: vacols_sequence_id
      )
    end
    let(:ineligible_reason) { nil }
    let(:vacols_id) { nil }
    let(:vacols_sequence_id) { nil }
    let(:vacols_case) { create(:case, case_issues: [create(:case_issue)]) }
    let(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

    context "when there is no associated legacy issue" do
      it "does not create a legacy issue" do
        subject

        expect(request_issue.legacy_issues).to be_empty
      end
    end

    context "when there is an associated legacy issue" do
      let(:vacols_id) { legacy_appeal.vacols_id }
      let(:vacols_sequence_id) { legacy_appeal.issues.first.vacols_sequence_id }

      context "when the veteran did not opt in their legacy issues" do
        let(:ineligible_reason) { "legacy_issue_not_withdrawn" }

        it "creates a legacy issue, but no opt-in" do
          subject

          expect(request_issue.legacy_issues.count).to eq 1
          expect(request_issue.legacy_issue_optin).to be_nil
        end
      end

      context "when legacy opt in is approved by the veteran" do
        let(:ineligible_reason) { nil }

        it "creates a legacy issue and an associated opt-in" do
          subject

          expect(request_issue.legacy_issue_optin.legacy_issue).to eq(request_issue.legacy_issues.first)
        end
      end
    end
  end

  context "#create_remand_supplemental_claims!" do
    before { setup_prior_claim_with_payee_code(appeal, veteran) }

    let(:veteran) { create(:veteran) }
    let(:appeal) do
      create(:appeal, number_of_claimants: 1, veteran_file_number: veteran.file_number)
    end

    subject { appeal.create_remand_supplemental_claims! }

    let!(:remanded_decision_issue) do
      create(
        :decision_issue,
        decision_review: appeal,
        disposition: "remanded",
        benefit_type: "compensation",
        caseflow_decision_date: decision_date
      )
    end

    let!(:remanded_decision_issue_processed_in_caseflow) do
      create(
        :decision_issue, decision_review: appeal, disposition: "remanded", benefit_type: "nca",
                         caseflow_decision_date: decision_date
      )
    end

    let(:decision_date) { 10.days.ago }
    let!(:decision_document) { create(:decision_document, decision_date: decision_date, appeal: appeal) }

    let!(:not_remanded_decision_issue) { create(:decision_issue, decision_review: appeal) }

    it "creates supplemental claim, request issues, and starts processing" do
      subject

      remanded_supplemental_claims = SupplementalClaim.where(decision_review_remanded: appeal)

      expect(remanded_supplemental_claims.count).to eq(2)

      vbms_remand = remanded_supplemental_claims.find_by(benefit_type: "compensation")
      expect(vbms_remand).to have_attributes(
        receipt_date: decision_date.to_date
      )
      expect(vbms_remand.request_issues.count).to eq(1)
      expect(vbms_remand.request_issues.first).to have_attributes(
        contested_decision_issue: remanded_decision_issue
      )
      expect(vbms_remand.end_product_establishments.first).to be_committed
      expect(vbms_remand.tasks).to be_empty

      caseflow_remand = remanded_supplemental_claims.find_by(benefit_type: "nca")
      expect(caseflow_remand).to have_attributes(
        receipt_date: decision_date.to_date
      )
      expect(caseflow_remand.request_issues.count).to eq(1)
      expect(caseflow_remand.request_issues.first).to have_attributes(
        contested_decision_issue: remanded_decision_issue_processed_in_caseflow
      )
      expect(caseflow_remand.end_product_establishments).to be_empty
      expect(caseflow_remand.tasks.first).to have_attributes(assigned_to: BusinessLine.find_by(url: "nca"))
    end
  end

  context "#document_fetcher" do
    let(:veteran_file_number) { "64205050" }
    let(:appeal) do
      create(:appeal, veteran_file_number: veteran_file_number)
    end

    it "returns a DocumentFetcher" do
      expect(appeal.document_fetcher.appeal).to eq(appeal)
      expect(appeal.document_fetcher.use_efolder).to eq(true)
    end
  end

  context "#latest_attorney_case_review" do
    let(:appeal) { create(:appeal) }
    let!(:task1) { create(:ama_attorney_task, appeal: appeal) }
    let!(:attorney_case_review1) { create(:attorney_case_review, task: task1, created_at: 2.days.ago) }
    let!(:attorney_case_review2) do
      task1.update!(status: Constants.TASK_STATUSES.completed)
      if appeal.tasks.open.of_type("JudgeDecisionReviewTask").any?
        appeal.tasks.open.find_by(type: "JudgeDecisionReviewTask").completed!
      end
      task2 = create(:ama_attorney_task, appeal: appeal)
      create(:attorney_case_review, task: task2, created_at: 1.day.ago)
    end

    subject { appeal.latest_attorney_case_review }

    it "returns the latest record" do
      expect(subject).to eq attorney_case_review2
    end
  end

  context "#overtime" do
    include_examples "toggle overtime"
  end

  context "#contestable_issues" do
    subject { appeal.contestable_issues }

    let(:veteran_file_number) { "64205050" }

    let!(:veteran) do
      Generators::Veteran.build(
        file_number: veteran_file_number,
        first_name: "Ed",
        last_name: "Merica",
        participant_id: "55443322"
      )
    end

    let(:receipt_date) { Time.zone.today }
    let(:appeal) do
      create(:appeal, veteran: veteran, receipt_date: receipt_date)
    end

    let(:another_review) do
      create(:higher_level_review, veteran_file_number: veteran_file_number, receipt_date: receipt_date)
    end

    let!(:past_decision_issue) do
      create(:decision_issue,
             decision_review: another_review,
             rating_profile_date: receipt_date - 1.day,
             benefit_type: another_review.benefit_type,
             decision_text: "something decided in the past",
             description: "past issue",
             participant_id: veteran.participant_id,
             end_product_last_action_date: receipt_date - 1.day)
    end

    let!(:future_decision_issue) do
      create(:decision_issue,
             decision_review: another_review,
             rating_profile_date: receipt_date + 1.day,
             rating_promulgation_date: receipt_date + 1.day,
             benefit_type: another_review.benefit_type,
             decision_text: "something was decided in the future",
             description: "future issue",
             participant_id: veteran.participant_id,
             end_product_last_action_date: receipt_date - 1.day)
    end

    # it "does not return Decision Issues in the future" do
    #   expect(subject.count).to eq(1)
    #   expect(subject.first.decision_issue.id).to eq(past_decision_issue.id)
    # end
  end

  context "async logic scopes" do
    let!(:appeal_requiring_processing_newly_submitted) do
      create(:appeal).tap(&:submit_for_processing!)
    end

    let!(:appeal_requiring_processing) do
      create(:appeal).tap do |appeal|
        appeal.submit_for_processing!
        appeal.update!(
          establishment_last_submitted_at: (Appeal.processing_retry_interval_hours + 1).hours.ago
        )
      end
    end

    let!(:appeal_processed) do
      create(:appeal).tap(&:processed!)
    end

    let!(:appeal_recently_attempted) do
      create(
        :appeal,
        establishment_attempted_at: (Appeal.processing_retry_interval_hours - 1).hours.ago
      )
    end

    let!(:appeal_attempts_ended) do
      create(
        :appeal,
        establishment_last_submitted_at: (Appeal::REQUIRES_PROCESSING_WINDOW_DAYS + 5).days.ago,
        establishment_attempted_at: (Appeal::REQUIRES_PROCESSING_WINDOW_DAYS + 1).days.ago
      )
    end

    context ".unexpired" do
      it "matches appeals still inside the processing window" do
        expect(Appeal.unexpired).to match_array(
          [appeal_requiring_processing, appeal_requiring_processing_newly_submitted]
        )
      end
    end

    context ".processable" do
      it "matches appeals eligible for processing" do
        expect(Appeal.processable).to match_array(
          [appeal_requiring_processing, appeal_attempts_ended, appeal_requiring_processing_newly_submitted]
        )
      end
    end

    context ".attemptable" do
      it "matches appeals that could be attempted" do
        expect(Appeal.attemptable).not_to include(appeal_recently_attempted)
      end
    end

    context ".requires_processing" do
      it "matches appeals that need to be reprocessed" do
        expect(Appeal.requires_processing).to match_array([appeal_requiring_processing])
      end
    end

    context ".expired_without_processing" do
      it "matches appeals unfinished but outside the retry window" do
        expect(Appeal.expired_without_processing).to eq([appeal_attempts_ended])
      end
    end
  end

  context "#establish!" do
    it { is_expected.to_not be_nil }
  end

  context "#every_request_issue_has_decision" do
    let(:appeal) { create(:appeal, request_issues: [request_issue]) }
    let(:request_issue) { create(:request_issue, decision_issues: decision_issues) }

    subject { appeal.every_request_issue_has_decision? }

    context "when no decision issues" do
      let(:decision_issues) { [] }

      it { is_expected.to eq false }
    end

    context "when decision issues" do
      let(:decision_issues) { [build(:decision_issue)] }

      it { is_expected.to eq true }
    end
  end

  context "#docket_number" do
    context "when receipt_date is defined" do
      let(:appeal) do
        create(:appeal, receipt_date: Time.new("2018", "04", "05").utc)
      end

      it "returns a docket number if id and receipt_date are defined" do
        expect(appeal.docket_number).to eq("180405-#{appeal.id}")
      end
    end

    context "when receipt_date is nil" do
      let(:appeal) do
        create(:appeal, receipt_date: nil)
      end

      it "returns Missing Docket Number" do
        expect(appeal.docket_number).to eq("Missing Docket Number")
      end
    end
  end

  context "#update_receipt_date!" do
    context "when receipt_date is defined" do
      let(:appeal) do
        create(:appeal, receipt_date: Date.new(2020, 11, 11))
      end

      it "returns a stream docket number if id and receipt_date are defined" do
        expect(appeal.stream_docket_number).to eq("201111-#{appeal.id}")
      end

      it "updates the stream docket number if receipt_date changes" do
        appeal.update_receipt_date!(receipt_date: Date.new(2020, 11, 12))
        expect(appeal.stream_docket_number).to eq("201112-#{appeal.id}")
      end
    end
  end

  context "#set_stream_docket_number_and_stream_type" do
    let(:appeal) { Appeal.new(veteran_file_number: "1234") }
    let(:receipt_date) { Date.new(2020, 1, 24) }

    it "persists an accurate value for stream_docket_number to the database" do
      appeal.save!
      expect(appeal.stream_docket_number).to be_nil
      appeal.receipt_date = receipt_date
      expect(appeal.docket_number).to eq("200124-#{appeal.id}")
      appeal.save!
      expect(appeal.stream_docket_number).to eq("200124-#{appeal.id}")
      appeal.stream_docket_number = "something else"
      appeal.save!
      expect(Appeal.where(stream_docket_number: "something else").count).to eq(1)
    end

    it "persists a non-NULL value for stream_docket_number as soon as possible" do
      appeal.receipt_date = receipt_date
      appeal.save!
      expect(Appeal.where(stream_docket_number: "200124-#{appeal.id}").count).to eq(1)
    end
  end

  context "#advanced_on_docket?" do
    context "when a claimant is advanced_on_docket? due to age" do
      let(:appeal) { create(:appeal, claimants: [create(:claimant, :advanced_on_docket_due_to_age)]) }

      it "returns true" do
        expect(appeal.advanced_on_docket?).to eq(true)
        expect(appeal.aod_based_on_age).to eq(true)
      end
    end

    context "when no claimant is advanced_on_docket? due to age" do
      let(:appeal) { create(:appeal) }

      it "returns false" do
        expect(appeal.advanced_on_docket?).to eq(false)
        expect(appeal.aod_based_on_age).to eq(false)
      end
    end

    context "when a claimant is advanced_on_docket? due to motion" do
      let(:appeal) { create(:appeal, :advanced_on_docket_due_to_motion) }

      it "returns true" do
        expect(appeal.advanced_on_docket?).to eq(true)
        expect(appeal.aod_based_on_age).to eq(false)
      end
    end
  end

  context "#find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id" do
    context "with a uuid (AMA appeal id)" do
      let(:veteran_file_number) { "64205050" }

      let(:appeal) do
        create(:appeal, veteran_file_number: veteran_file_number)
      end

      it "finds the appeal" do
        expect(Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(appeal.uuid)).to \
          eq(appeal)
      end

      it "returns RecordNotFound for a non-existant one" do
        made_up_uuid = "11111111-aaaa-bbbb-CCCC-999999999999"
        expect { Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(made_up_uuid) }.to \
          raise_exception(ActiveRecord::RecordNotFound, "Couldn't find Appeal")
      end
    end

    context "with a legacy appeal" do
      let(:vacols_issue) { create(:case_issue) }
      let(:vacols_case) { create(:case, case_issues: [vacols_issue]) }
      let(:legacy_appeal) do
        create(:legacy_appeal, vacols_case: vacols_case)
      end

      it "finds the appeal" do
        legacy_appeal.save
        expect(Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(legacy_appeal.vacols_id)).to \
          eq(legacy_appeal)
      end

      it "returns RecordNotFound for a non-existant one" do
        made_up_non_uuid = "9876543"
        expect do
          Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(made_up_non_uuid)
        end.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end
  end

  context "#appellant_first_name" do
    subject { appeal.appellant_first_name }

    context "when appeal has claimants" do
      let(:appeal) { create(:appeal, number_of_claimants: 1) }

      it "returns claimant's name" do
        expect(subject).to_not eq nil
        expect(subject).to eq appeal.claimant.first_name
      end
    end

    context "when appeal doesn't have claimants" do
      let(:appeal) { create(:appeal, number_of_claimants: 0) }

      it { is_expected.to eq nil }
    end
  end

  context "#appellant_middle_initial" do
    subject { appeal.appellant_middle_initial }

    context "when appeal has claimants" do
      let(:appeal) { create(:appeal, number_of_claimants: 1) }

      it "returns non-nil string of size 1" do
        expect(subject).to_not eq nil
        expect(subject.size).to eq 1
      end
    end

    context "when appeal doesn't have claimants" do
      let(:appeal) { create(:appeal, number_of_claimants: 0) }

      it { is_expected.to eq nil }
    end
  end

  context "when claimants have different poas" do
    let(:participant_id_with_pva) { "1234" }
    let(:participant_id_with_aml) { "5678" }

    let(:appeal) do
      create(:appeal, claimants: [
               create(:claimant, participant_id: participant_id_with_pva),
               create(:claimant, participant_id: participant_id_with_aml)
             ])
    end

    let!(:vso) do
      Vso.create(
        name: "Paralyzed Veterans Of America",
        role: "VSO",
        url: "paralyzed-veterans-of-america",
        participant_id: Fakes::BGSServicePOA::PARALYZED_VETERANS_VSO_PARTICIPANT_ID
      )
    end

    before do
      allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
        .with([participant_id_with_pva]) do
          { participant_id_with_pva => Fakes::BGSServicePOA.paralyzed_veterans_vso_mapped }
        end
      allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
        .with([participant_id_with_aml]) do
          { participant_id_with_aml => Fakes::BGSServicePOA.american_legion_vso_mapped }
        end
    end

    context "#power_of_attorney" do
      it "returns the first claimant's power of attorney" do
        expect(appeal.power_of_attorney.representative_name).to eq(Fakes::BGSServicePOA::AMERICAN_LEGION_VSO_NAME)
      end
    end

    context "#power_of_attorneys" do
      it "returns all claimants power of attorneys" do
        expect(appeal.power_of_attorneys[0].representative_name)
          .to eq(Fakes::BGSServicePOA::PARALYZED_VETERANS_VSO_NAME)
        expect(appeal.power_of_attorneys[1].representative_name)
          .to eq(Fakes::BGSServicePOA::AMERICAN_LEGION_VSO_NAME)
      end

      context "one claimant has no POA" do
        before do
          allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
            .with([participant_id_with_pva]).and_return({})
          allow(appeal).to receive(:veteran_file_number) { "no-such-file-number" }
        end

        it "ignores nil values" do
          expect(appeal.power_of_attorneys.count).to eq(1)
        end
      end
    end

    context "#representatives" do
      it "returns all representatives this appeal has that exist in our DB" do
        expect(appeal.representatives.count).to eq(1)
        expect(appeal.representatives.first.name).to eq("Paralyzed Veterans Of America")
      end

      context "when there is no VSO" do
        let(:participant_id_with_nil) { "1234" }
        before do
          allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
            .with([participant_id_with_nil]).and_return(
              participant_id_with_pva => nil
            )
        end
        let(:appeal) do
          create(:appeal, claimants: [create(:claimant, participant_id: participant_id_with_nil)])
        end
        let!(:vso) do
          Vso.create(
            name: "Test VSO",
            url: "test-vso"
          )
        end

        it "does not return VSOs with nil participant_id" do
          expect(appeal.representatives).to eq([])
        end
      end
    end
  end

  context ".create_tasks_on_intake_success!" do
    let!(:appeal) { create(:appeal) }

    subject { appeal.create_tasks_on_intake_success! }

    it "creates root and vso tasks" do
      expect_any_instance_of(InitialTasksFactory).to receive(:create_root_and_sub_tasks!).once

      subject
    end

    context "request issue has non-comp business line" do
      let!(:appeal) do
        create(:appeal, request_issues: [
                 create(:request_issue, benefit_type: :education),
                 create(:request_issue, benefit_type: :compensation),
                 create(:request_issue, :unidentified)
               ])
      end

      it "creates root task and veteran record request task" do
        expect(VeteranRecordRequest).to receive(:create!).once

        subject
      end
    end

    context "request issue is missing benefit type" do
      let!(:appeal) do
        create(:appeal, request_issues: [
                 create(:request_issue, benefit_type: "unknown"),
                 create(:request_issue, :unidentified)
               ])
      end

      it "raises MissingBusinessLine exception" do
        expect { subject }.to raise_error(Caseflow::Error::MissingBusinessLine)
      end
    end

    context "creating translation tasks" do
      let!(:mock_response) { HTTPI::Response.new(200, {}, {}.to_json) }
      let(:bgs_veteran_state) { nil }
      let(:bgs_veteran_record) { { state: bgs_veteran_state } }
      let(:validated_veteran_state) { nil }
      let(:mock_va_dot_gov_address) { { state_code: validated_veteran_state } }
      let(:veteran) { create(:veteran, bgs_veteran_record: bgs_veteran_record) }
      let(:appeal) { create(:appeal, veteran: veteran) }

      context "VADotGovService is responsive" do
        before do
          valid_address_response = ExternalApi::VADotGovService::AddressValidationResponse.new(mock_response)
          allow(valid_address_response).to receive(:data).and_return(mock_va_dot_gov_address)
          allow(VADotGovService).to receive(:validate_address)
            .and_return(valid_address_response)
        end

        context "the service returns a state code" do
          context "the state code is PR or PI" do
            let(:validated_veteran_state) { "PR" }

            it "creates a translation task" do
              expect(TranslationTask).to receive(:create_from_parent).once.with(kind_of(DistributionTask))

              subject
            end

            context "the bgs veteran record has a different state code" do
              let(:validated_veteran_state) { "PI" }
              let(:bgs_veteran_state) { "NV" }

              it "prefers the service state code and creates a translation task" do
                expect(TranslationTask).to receive(:create_from_parent).once.with(kind_of(DistributionTask))

                subject
              end
            end
          end

          context "the state code is not PR or PI" do
            let(:validated_veteran_state) { "NV" }

            it "doesn't create a translation task" do
              translation_task_count = TranslationTask.all.count
              subject
              expect(TranslationTask.all.count).to eq(translation_task_count)
            end
          end
        end
      end

      context "the VADotGovService is not responsive" do
        let(:message) { { "messages" => [{ "key" => "AddressCouldNotBeFound" }] } }
        let(:error) { Caseflow::Error::VaDotGovServerError.new(code: "500", message: message) }

        before do
          allow(VADotGovService).to receive(:send_va_dot_gov_request).and_raise(error)
        end

        it "fails silently" do
          expect { subject }.to_not raise_error
        end

        context "the bgs veteran record has no state code" do
          it "doesn't create a translation task" do
            translation_task_count = TranslationTask.all.count
            subject
            expect(TranslationTask.all.count).to eq(translation_task_count)
          end
        end

        context "the bgs veteran record has a state code" do
          context "the state code is PR or PI" do
            let(:bgs_veteran_state) { "PI" }

            it "creates a translation task" do
              expect(TranslationTask).to receive(:create_from_parent).once.with(kind_of(DistributionTask))

              subject
            end
          end

          context "the state code is not PR or PI" do
            let(:bgs_veteran_state) { "NV" }

            it "doesn't create a translation task" do
              translation_task_count = TranslationTask.all.count
              subject
              expect(TranslationTask.all.count).to eq(translation_task_count)
            end
          end
        end
      end
    end
  end

  context "#assigned_to_location" do
    context "if the RootTask status is completed" do
      let(:appeal) { create(:appeal) }

      before do
        create(:root_task, :completed, appeal: appeal)
        create(:schedule_hearing_task, :completed, appeal: appeal)
      end

      it "returns Post-decision" do
        expect(appeal.assigned_to_location).to eq(COPY::CASE_LIST_TABLE_POST_DECISION_LABEL)
      end
    end

    context "if there are no active tasks" do
      let(:appeal) { create(:appeal) }
      it "returns 'other close'" do
        expect(appeal.assigned_to_location).to eq(:other_close.to_s.titleize)
      end
    end

    context "if the only active task is a RootTask" do
      let(:appeal) { create(:appeal) }
      let(:appeal_with_cancelled_dispatch) do
        sji = SanitizedJsonImporter.from_file("spec/records/appeal-53008.json", verbosity: 0)
        sji.import
        sji.imported_records[Appeal.table_name].first
      end

      before do
        create(:root_task, :in_progress, appeal: appeal)
      end

      it "returns Unassigned" do
        expect(appeal.assigned_to_location).to eq(COPY::CASE_LIST_TABLE_UNASSIGNED_LABEL)
        expect(appeal_with_cancelled_dispatch.assigned_to_location).to eq(COPY::CASE_LIST_TABLE_UNASSIGNED_LABEL)
      end
    end

    context "if there are active TrackVeteranTask, TimedHoldTask, and RootTask" do
      let(:appeal) { create(:appeal) }
      let(:today) { Time.zone.today }

      let(:root_task) { create(:root_task, :in_progress, appeal: appeal) }
      before do
        create(:track_veteran_task, :in_progress, parent: root_task, updated_at: today + 21)
        create(:timed_hold_task, :in_progress, parent: root_task, updated_at: today + 21)
      end

      describe "when there are no other tasks" do
        it "returns Unassigned" do
          expect(appeal.assigned_to_location).to eq(COPY::CASE_LIST_TABLE_UNASSIGNED_LABEL)
        end
      end

      describe "when there is an actionable task with an assignee" do
        let(:assignee) { create(:user) }
        let!(:task) do
          create(:ama_attorney_task, :in_progress, assigned_to: assignee, parent: root_task)
        end

        it "returns the actionable task's label and does not include nonactionable tasks in its determinations" do
          expect(appeal.assigned_to_location).to(
            eq(assignee.css_id), appeal.structure_render(:id, :status, :created_at, :assigned_to_id)
          )
        end
      end
    end

    context "if there is an assignee" do
      let(:organization) { create(:organization) }
      let(:appeal_organization) { create(:appeal) }
      let(:user) { create(:user) }
      let(:appeal_user) { create(:appeal) }
      let(:appeal_on_hold) { create(:appeal) }
      let(:today) { Time.zone.today }

      before do
        organization_root_task = create(:root_task, appeal: appeal_organization)
        create(:ama_task, assigned_to: organization, parent: organization_root_task)

        user_root_task = create(:root_task, appeal: appeal_user)
        create(:ama_task, assigned_to: user, parent: user_root_task)

        on_hold_root = create(:root_task, appeal: appeal_on_hold, updated_at: today - 1)
        create(:ama_task, :on_hold, parent: on_hold_root, updated_at: today + 1)

        # These tasks are the most recently updated but should be ignored in the determination
        create(:track_veteran_task, :in_progress, appeal: appeal, updated_at: today + 20)
        create(:timed_hold_task, :in_progress, appeal: appeal, updated_at: today + 20)
      end

      it "if the most recent assignee is an organization it returns the organization name" do
        expect(appeal_organization.assigned_to_location).to eq(organization.name)
      end

      it "if the most recent assignee is not an organization it returns the id" do
        expect(appeal_user.assigned_to_location).to eq(user.css_id)
      end

      it "if the task is on hold but there isn't an assignee it returns something" do
        expect(appeal_on_hold.assigned_to_location).not_to eq(nil)
      end
    end
  end

  context "is taskable" do
    context ".assigned_attorney" do
      let!(:attorney) { create(:user) }
      let!(:attorney2) { create(:user) }
      let!(:appeal) { create(:appeal) }
      let(:judge_decision_review_task) { create(:ama_judge_decision_review_task, appeal: appeal) }
      let!(:task) do
        create(:ama_attorney_task, parent: judge_decision_review_task, assigned_to: attorney,
                                   appeal: appeal, created_at: 1.day.ago)
      end
      let!(:task2) do
        task.completed!
        create(:ama_attorney_task, parent: judge_decision_review_task, assigned_to: attorney2,
                                   appeal: appeal, created_at: 1.hour.ago)
      end

      subject { appeal.assigned_attorney }

      it "returns the assigned attorney for the most recent non-cancelled AttorneyTask" do
        expect(subject).to eq attorney2
      end

      it "should know the right assigned attorney with a cancelled task" do
        task2.cancelled!
        expect(subject).to eq attorney
      end

      context "when there is a more recent DocketSwitch attorney task" do
        let(:judge) { create(:user, :with_vacols_judge_record, full_name: "Judge the First", css_id: "JUDGE_1") }
        let(:root_task) { create(:root_task, appeal: appeal) }
        let!(:ds_task) do
          create(:docket_switch_denied_task, parent: root_task, appeal: appeal, assigned_to: attorney,
                                             assigned_by: judge, created_at: 1.minute.ago)
        end

        it "ignores the attorney assigned to the DocketSwitch attorney task" do
          expect(subject).to eq attorney2
        end
      end
    end

    context ".assigned_judge" do
      let(:judge) { create(:user) }
      let(:judge2) { create(:user) }
      let(:judge3) { create(:user) }
      let(:appeal) { create(:appeal) }
      let!(:task) do
        create(:ama_judge_assign_task, :cancelled, assigned_to: judge,
                                                   appeal: appeal, created_at: 1.day.ago)
      end
      let!(:task2) { create(:ama_judge_assign_task, assigned_to: judge2, appeal: appeal) }
      subject { appeal.assigned_judge }

      context "with one cancelled task" do
        it "returns the assigned judge for the most recent open JudgeTask" do
          expect(subject).to eq judge2
        end
      end

      context "with multiple cancelled tasks" do
        before { task2.cancelled! }
        let!(:task3) { create(:ama_judge_assign_task, assigned_to: judge3, appeal: appeal, created_at: 1.day.ago) }

        it "should return the assigned judge for the open task" do
          expect(subject).to eq judge3
        end
      end
    end
  end

  context ".active?" do
    subject { appeal.active? }

    context "when there are no tasks for an appeal" do
      let(:appeal) { create(:appeal) }

      it "should indicate the appeal is not active" do
        expect(subject).to eq(false)
      end
    end

    context "when there are only completed tasks for an appeal" do
      let(:appeal) { create(:appeal) }

      before do
        create_list(:task, 6, :completed, appeal: appeal)
      end

      it "should indicate the appeal is not active" do
        expect(subject).to eq(false)
      end
    end

    context "when there are incomplete tasks for an appeal" do
      let(:appeal) { create(:appeal) }

      before do
        create_list(:task, 3, :in_progress, appeal: appeal)
      end

      it "should indicate the appeal is active" do
        expect(subject).to eq(false)
      end
    end
  end

  context "#cavc?" do
    subject { appeal.cavc? }

    context "for original appeal" do
      it "returns false" do
        expect(subject).to eq(false)
      end
    end

    context "for cavc stream" do
      let(:appeal) { create(:appeal, stream_type: Constants.AMA_STREAM_TYPES.court_remand) }

      it "returns true" do
        expect(subject).to eq(true)
      end
    end
  end

  describe "#cavc_remand" do
    subject { appeal.cavc_remand }

    context "an original appeal" do
      let(:appeal) { create(:appeal) }
      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "a remand appeal" do
      let(:cavc_remand) { create(:cavc_remand) }
      let(:appeal) { cavc_remand.remand_appeal }

      it "returns the CavcRemand" do
        expect(subject).to eq(cavc_remand)
      end
    end
  end

  describe "#status" do
    it "returns BVAAppealStatus object" do
      expect(appeal.status).to be_a(BVAAppealStatus)
      expect(appeal.status.to_s).to eq("UNKNOWN") # zero tasks
    end
  end

  context "#set_target_decision_date!" do
    let(:direct_review_appeal) do
      create(:appeal,
             docket_type: Constants.AMA_DOCKETS.direct_review)
    end
    let(:evidence_submission_appeal) do
      create(:appeal,
             docket_type: Constants.AMA_DOCKETS.evidence_submission)
    end

    context "with direct review appeal" do
      subject { direct_review_appeal }
      it "sets target decision date" do
        subject.set_target_decision_date!
        expect(subject.target_decision_date).to eq(
          subject.receipt_date + Constants.DISTRIBUTION.direct_docket_time_goal.days
        )
      end
    end

    context "with not direct review appeal" do
      subject { evidence_submission_appeal }
      it "does not set target date" do
        subject.set_target_decision_date!
        expect(subject.target_decision_date).to eq(nil)
      end
    end
  end

  describe "#stuck?" do
    context "Appeal has BvaDispatchTask completed but still on hold" do
      let(:appeal) do
        appeal = create(:appeal, :with_post_intake_tasks)
        create(:bva_dispatch_task, :completed, appeal: appeal)
        create(:decision_document, citation_number: "A18123456", appeal: appeal)
        appeal
      end

      it "returns true" do
        expect(appeal.stuck?).to eq(true)
      end
    end
  end

  describe "#caregiver_has_issues?" do
    subject { appeal.caregiver_has_issues? }

    context "appeal has no caregiver tasks" do
      let(:appeal) { create(:appeal, request_issues: [create(:request_issue, :nonrating)]) }

      it { expect(subject).to eq false }
    end

    context "appeal has caregiver tasks" do
      let(:appeal) { create(:appeal, :with_vha_issue) }

      it { expect(subject).to eq true }
    end
  end

  describe "#contested_claim?" do
    subject { appeal.contested_claim? }

    before { FeatureToggle.enable!(:indicator_for_contested_claims) }
    after { FeatureToggle.disable!(:indicator_for_contested_claims) }

    let(:request_issues) do
      [
        create(:request_issue, benefit_type: benefit_type, nonrating_issue_category: issue_category)
      ]
    end
    let(:appeal) { create(:appeal, request_issues: request_issues) }

    context "when issue category falls under contested claims" do
      context "contains string 'Contested Claim'" do
        let(:benefit_type) { "compensation" }
        let(:issue_category) { "Contested Claims - Insurance" }

        it "returns true" do
          expect(subject).to be_truthy
        end
      end

      context "contains string 'Contested Death'" do
        let(:benefit_type) { "compensation" }
        let(:issue_category) { "Contested Death Claim | Other" }

        it "returns true" do
          expect(subject).to be_truthy
        end
      end

      context "contains string 'Apportionment'" do
        let(:benefit_type) { "compensation" }
        let(:issue_category) { "Contested Claims - Apportionment" }

        it "returns true" do
          expect(subject).to be_truthy
        end
      end
    end

    context "when issue category doesn't fall under contested claims" do
      let(:benefit_type) { "fiduciary" }
      let(:issue_category) { "Appointment of a Fiduciary (38 CFR 13.100)" }

      it "returns false" do
        expect(subject).to be_falsey
      end
    end

    context "when the request issue is a rating issue" do
      let(:request_issues) do
        [
          create(:request_issue, :rating)
        ]
      end

      it "returns false" do
        expect(subject).to be_falsey
      end
    end
  end

  describe "#mst?" do
    subject { appeal.mst? }

    before { FeatureToggle.enable!(:mst_pact_identification) }
    after { FeatureToggle.disable!(:mst_pact_identification) }

    let(:request_issues) do
      [
        create(:request_issue, mst_status: mst_status)
      ]
    end

    context "when request issues with mst_status are associated with appeal" do
      let(:appeal) { create(:appeal, request_issues: request_issues) }

      context "when mst_status is enabled" do
        let(:mst_status) { true }

        it "returns true" do
          expect(subject).to be_truthy
        end
      end

      context "when mst_status is disabled" do
        let(:mst_status) { false }

        it "returns false" do
          expect(subject).to be_falsey
        end
      end
    end

    context "when request issues with mst_status are not associated with appeal and has special_issue_list" do
      let!(:appeal) { create(:appeal) }

      before do
        Timecop.freeze(Time.utc(2023, 4, 28, 12, 0, 0))
        create(:special_issue_list, appeal_id: appeal.id, military_sexual_trauma: military_sexual_trauma)
      end

      after do
        Timecop.return
      end

      context "when military_sexual_trauma is enabled" do
        let(:military_sexual_trauma) { true }

        it "returns true" do
          expect(subject).to be_truthy
        end
      end

      context "when military_sexual_trauma is disabled" do
        let(:military_sexual_trauma) { false }

        it "returns false" do
          expect(subject).to be_falsey
        end
      end
    end
  end

  describe "#pact?" do
    subject { appeal.pact? }

    before { FeatureToggle.enable!(:mst_pact_identification) }
    after { FeatureToggle.disable!(:mst_pact_identification) }

    let(:request_issues) do
      [
        create(:request_issue, pact_status: pact_status)
      ]
    end

    context "when request issues with pact_status are associated with appeal" do
      let(:appeal) { create(:appeal, request_issues: request_issues) }

      context "when pact_status is enabled" do
        let(:pact_status) { true }

        it "returns true" do
          expect(subject).to be_truthy
        end
      end

      context "when pact_status is disabled" do
        let(:pact_status) { false }

        it "returns false" do
          expect(subject).to be_falsey
        end
      end
    end
  end

  describe "#vacate_type" do
    subject { appeal.vacate_type }

    context "Appeal is a vacatur and has a post-decision motion" do
      let(:original) { create(:appeal, :with_straight_vacate_stream) }
      let(:appeal) { Appeal.vacate.find_by(stream_docket_number: original.docket_number) }

      it "returns the post-decision motion's vacate type" do
        expect(subject).to eq "straight_vacate"
      end
    end

    context "Appeal is not a vacatur" do
      let(:appeal) { create(:appeal) }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  shared_examples "existing BvaDispatchTask" do |status, result|
    let(:user) { create(:user) }

    before do
      BvaDispatch.singleton.add_user(user)
      dispatch_task = BvaDispatchTask.create_from_root_task(appeal.root_task)
      dispatch_task.descendants.each { |task| task.update_column(:status, status) }
    end

    it "should return #{result}" do
      expect(subject).to eq(result)
    end
  end

  shared_examples "depends on existing BvaDispatchTask" do
    context "no existing BvaDispatchTask" do
      it "should return true" do
        expect(subject).to eq(true)
      end
    end

    context "existing open BvaDispatchTask" do
      include_examples "existing BvaDispatchTask",
                       Constants.TASK_STATUSES.in_progress,
                       false
    end

    context "existing complete BvaDispatchTask" do
      include_examples "existing BvaDispatchTask",
                       Constants.TASK_STATUSES.completed,
                       false
    end

    context "existing cancelled BvaDispatchTask" do
      include_examples "existing BvaDispatchTask",
                       Constants.TASK_STATUSES.cancelled,
                       true

      context "and existing open BvaDispatchTask" do
        include_examples "existing BvaDispatchTask",
                         Constants.TASK_STATUSES.assigned,
                         false
      end

      context "and existing completed BvaDispatchTask" do
        include_examples "existing BvaDispatchTask",
                         Constants.TASK_STATUSES.completed,
                         false
      end
    end
  end

  describe ".ready_for_bva_dispatch?" do
    subject { appeal.ready_for_bva_dispatch? }

    context "no complete JudgeDecisionReviewTask" do
      it "should return false" do
        expect(subject).to eq(false)
      end
    end

    context "has complete JudgeDecisionReviewTask" do
      let(:appeal) do
        create(:appeal,
               :at_judge_review,
               docket_type: Constants.AMA_DOCKETS.direct_review)
      end
      before do
        JudgeDecisionReviewTask.find_by(appeal: appeal)
          .update_column(:status, Constants.TASK_STATUSES.completed)
      end

      context "and an open JudgeDecisionReviewTask" do
        before do
          JudgeDecisionReviewTask.create!(appeal: appeal, assigned_to: create(:user), parent: appeal.root_task)
        end

        it "should return false" do
          expect(subject).to eq(false)
        end
      end

      context "no QualityReviewTask" do
        include_examples "depends on existing BvaDispatchTask"
      end

      context "existing open QualityReviewTask" do
        let(:user) { create(:user) }
        before do
          BvaDispatch.singleton.add_user(user)
          QualityReviewTask.create_from_root_task(appeal.root_task)
        end

        it "should return false" do
          expect(subject).to eq(false)
        end
      end

      context "existing closed QualityReviewTask" do
        let(:user) { create(:user) }
        before do
          qr_task = QualityReviewTask.create_from_root_task(appeal.root_task)
          qr_task.descendants.each { |task| task.update_column(:status, Constants.TASK_STATUSES.completed) }
        end

        include_examples "depends on existing BvaDispatchTask"
      end
    end
  end

  describe ".ready_for_distribution?" do
    let(:appeal) { create(:appeal) }
    let(:distribution_task) { create(:distribution_task, appeal: appeal, assigned_to: Bva.singleton) }

    it "is set to assigned and ready for distribution is tracked when all child tasks are completed" do
      child_task = create(:informal_hearing_presentation_task, parent: distribution_task)
      expect(appeal.ready_for_distribution?).to eq(false)

      child_task.update!(status: "completed")
      expect(appeal.ready_for_distribution?).to eq(true)

      another_child_task = create(:informal_hearing_presentation_task, parent: distribution_task)
      expect(appeal.ready_for_distribution?).to eq(false)

      another_child_task.update!(status: "completed")
      expect(appeal.ready_for_distribution?).to eq(true)
    end
  end

  describe "#latest_informal_hearing_presentation_task" do
    let(:appeal) { create(:appeal) }

    it_behaves_like "latest informal hearing presentation task"
  end

  describe "validate issue timeliness" do
    subject { appeal.untimely_issues_report(receipt_date) }

    let(:appeal) { create(:appeal, request_issues: request_issues) }
    let(:receipt_date) { 7.days.ago }
    let(:request_issues) { [timely_request_issue] }
    let(:timely_request_issue) { create(:request_issue, decision_date: receipt_date - 365.days) }
    let(:untimely_request_issue) { create(:request_issue, decision_date: 2.years.ago) }
    let(:inactive_untimely_request_issue) { create(:request_issue, :removed, decision_date: 2.years.ago) }
    let(:untimely_request_issue_with_exemption) do
      create(:request_issue,
             decision_date: 2.years.ago,
             untimely_exemption: true)
    end

    context "appeal only has issues that are timely with the new date" do
      let(:request_issues) { [timely_request_issue, untimely_request_issue_with_exemption] }

      it { is_expected.to be nil }

      context "The receipt date is before the decision date" do
        let(:receipt_date) { 3.years.ago }
        let(:timely_request_issue) { create(:request_issue, decision_date: 365.days.ago) }

        it "considers the issues untimely" do
          expect(subject[:affected_issues].count).to eq(request_issues.count)
          expect(subject[:unaffected_issues].count).to eq(0)
        end
      end
    end

    context "appeal has an issue that would be untimely with the new date" do
      let(:request_issues) { [timely_request_issue, untimely_request_issue] }

      it "reflects the untimely issue" do
        expect(subject[:affected_issues].first.id).to eq(untimely_request_issue.id)
        expect(subject[:unaffected_issues].first.id).to eq(timely_request_issue.id)
      end

      context "the untimely issue is closed" do
        let(:request_issues) { [timely_request_issue, inactive_untimely_request_issue] }

        it { is_expected.to be nil }
      end
    end
  end

  describe "can_redistribute_appeal?" do
    let!(:distributed_appeal_can_redistribute) do
      create(:appeal,
             :assigned_to_judge,
             docket_type: Constants.AMA_DOCKETS.direct_review,
             associated_judge: judge_user)
    end
    let!(:distributed_appeal_cannot_redistribute) do
      create(:appeal,
             :with_schedule_hearing_tasks,
             docket_type: Constants.AMA_DOCKETS.direct_review,
             associated_judge: judge_user,
             associated_attorney: attorney_user)
    end
    let!(:judge_user) { create(:user, :with_vacols_judge_record, full_name: "Judge Judy", css_id: "JUDGE_2") }
    let!(:judge_staff) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }
    let(:judge_team) { JudgeTeam.create_for_judge(judge_user) }
    let(:attorney_user) { create(:user) }
    let!(:attorney_staff) { create(:staff, :attorney_role, user: attorney_user) }
    let!(:attorney_on_judge_team) { judge_team.add_user(attorney_user) }
    let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

    let!(:past_distribution) { Distribution.create!(judge: judge_user) }
    let(:docket) { DirectReviewDocket.new }
    before do
      distributed_appeal_can_redistribute.tasks.last.update!(status: Constants.TASK_STATUSES.cancelled)
      past_distribution.completed!
    end

    context "when an appeal has no open tasks other than RootTask or TrackVeteranTask" do
      subject { distributed_appeal_can_redistribute.can_redistribute_appeal? }
      it "returns true " do
        expect(subject).to be true
      end
    end

    context "when an appeal has open tasks" do
      subject { distributed_appeal_cannot_redistribute.can_redistribute_appeal? }
      it "returns false" do
        expect(subject).to be false
      end
    end
  end

  describe "split_appeal" do
    let!(:regular_user) do
      create(:user, css_id: "APPEAL_USER")
    end

    context "when an appeal has numerous issues" do
      it "should duplicate the appeals and numerous issues for the same veteran" do
        appeal_with_numerous_issues = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        all_request_issues = appeal_with_numerous_issues.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        if appeal.evidence_submission_docket? && (appeal.docket_name == "evidence_submission")
          dup_appeal = appeal_with_numerous_issues.amoeba_dup
          dup_appeal.save
          dup_appeal.finalize_split_appeal(appeal_with_numerous_issues, params)

          expect(dup_appeal.id).not_to eq(appeal_with_numerous_issues.id)
          expect(dup_appeal.uuid).not_to eq(appeal_with_numerous_issues.uuid)
          expect(dup_appeal.veteran_file_number).to eq(appeal_with_numerous_issues.veteran_file_number)
          expect(dup_appeal.request_issues.count).to eq(appeal_with_numerous_issues.request_issues.count)
          expect(dup_appeal.veteran_is_not_claimant).to eq(appeal_with_numerous_issues.veteran_is_not_claimant)
          expect(dup_appeal.aod_based_on_age)
            .to eq(!!appeal_with_numerous_issues.aod_based_on_age) # Returns boolean, it should be nil
          expect(dup_appeal.changed_hearing_request_type)
            .to eq(appeal_with_numerous_issues.changed_hearing_request_type)
          expect(dup_appeal.closest_regional_office).to eq(appeal_with_numerous_issues.closest_regional_office)
          expect(dup_appeal.docket_range_date).to eq(appeal_with_numerous_issues.docket_range_date)
          expect(dup_appeal.docket_type).to eq(appeal_with_numerous_issues.docket_type)
          expect(dup_appeal.established_at).to eq(appeal_with_numerous_issues.established_at)
          expect(dup_appeal.establishment_attempted_at).to eq(appeal_with_numerous_issues.establishment_attempted_at)
          expect(dup_appeal.establishment_error).to eq(appeal_with_numerous_issues.establishment_error)
          expect(dup_appeal.establishment_last_submitted_at)
            .to eq(appeal_with_numerous_issues.establishment_last_submitted_at)
          expect(dup_appeal.establishment_processed_at).to eq(appeal_with_numerous_issues.establishment_processed_at)
          expect(dup_appeal.establishment_submitted_at).to eq(appeal_with_numerous_issues.establishment_submitted_at)
          expect(dup_appeal.filed_by_va_gov).to eq(appeal_with_numerous_issues.filed_by_va_gov)
          expect(dup_appeal.homelessness).to eq(appeal_with_numerous_issues.homelessness)
          expect(dup_appeal.legacy_opt_in_approved).to eq(appeal_with_numerous_issues.legacy_opt_in_approved)
          expect(dup_appeal.homelessness).to eq(appeal_with_numerous_issues.homelessness)
          expect(dup_appeal.poa_participant_id).to eq(appeal_with_numerous_issues.poa_participant_id)
          expect(dup_appeal.receipt_date).to eq(appeal_with_numerous_issues.receipt_date)
          expect(dup_appeal.stream_docket_number).to eq(appeal_with_numerous_issues.stream_docket_number)
          expect(dup_appeal.stream_type).to eq(appeal_with_numerous_issues.stream_type)
          expect(dup_appeal.target_decision_date).to eq(appeal_with_numerous_issues.target_decision_date)
          expect(dup_appeal.poa_participant_id).to eq(appeal_with_numerous_issues.poa_participant_id)
        end
      end
    end

    context "when an appeal has hearings" do
      it "should duplicate the appeals and hearings for the same veteran" do
        appeal_with_hearings = create(
          :appeal, docket_type: Constants.AMA_DOCKETS.hearing,
                   request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        all_request_issues = appeal_with_hearings.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: appeal_with_hearings.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        original_hearing = create(:hearing, appeal: appeal_with_hearings)
        if appeal_with_hearings.hearing_docket? && (appeal_with_hearings.docket_name == "hearing")
          dup_appeal = appeal_with_hearings.amoeba_dup
          dup_appeal.save
          dup_appeal.finalize_split_appeal(appeal_with_hearings, params)
          duplicated_hearing = dup_appeal.hearings.first
          expect(dup_appeal.id).not_to eq(appeal_with_hearings.id)
          expect(dup_appeal.uuid).not_to eq(appeal_with_hearings.uuid)
          expect(dup_appeal.veteran_file_number).to eq(appeal_with_hearings.veteran_file_number)
          expect(dup_appeal.request_issues.count).to eq(appeal_with_hearings.request_issues.count)
          expect(dup_appeal.hearings.count).to eq(appeal_with_hearings.hearings.count)
          expect(duplicated_hearing.id).not_to eq(original_hearing.id)
          expect(duplicated_hearing.uuid).not_to eq(original_hearing.uuid)
          expect(duplicated_hearing.appeal_id).not_to eq(original_hearing.appeal_id)
          expect(duplicated_hearing.updated_by_id).to eq(original_hearing.updated_by_id)
          expect(duplicated_hearing.bva_poc).to eq(original_hearing.bva_poc)
          expect(duplicated_hearing.created_by_id).to eq(original_hearing.created_by_id)
          expect(duplicated_hearing.disposition).to eq(original_hearing.disposition)
          expect(duplicated_hearing.evidence_window_waived).to eq(original_hearing.evidence_window_waived)
          expect(duplicated_hearing.hearing_day_id).to eq(original_hearing.hearing_day_id)
          expect(duplicated_hearing.judge_id).to eq(original_hearing.judge_id)
          expect(duplicated_hearing.military_service).to eq(original_hearing.military_service)
          expect(duplicated_hearing.notes).to eq(original_hearing.notes)
          expect(duplicated_hearing.prepped).to eq(original_hearing.prepped)
          expect(duplicated_hearing.representative_name).to eq(original_hearing.representative_name)
          expect(duplicated_hearing.room).to eq(original_hearing.room)
          expect(duplicated_hearing.scheduled_time).to eq(original_hearing.scheduled_time)
          expect(duplicated_hearing.summary).to eq(original_hearing.summary)
          expect(duplicated_hearing.transcript_requested).to eq(original_hearing.transcript_requested)
          expect(duplicated_hearing.transcript_sent_date).to eq(original_hearing.transcript_sent_date)
        end
      end
    end

    context "when an appeal has hearing email recipients" do
      it "should duplicate the appeals and hearing email recipients for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }
        original_hearing = create(:hearing, appeal: original_appeal)
        original_hearing_email_recipient = create(:hearing_email_recipient, hearing: original_hearing)
        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        duplicated_hearing_email_recipient = dup_appeal.hearings.first.email_recipients.first
        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_appeal.email_recipients.count).to eq(original_appeal.email_recipients.count)
        expect(duplicated_hearing_email_recipient.id).not_to eq(original_hearing_email_recipient.id)
        expect(duplicated_hearing_email_recipient.hearing_type).to eq(original_hearing_email_recipient.hearing_type)
        expect(duplicated_hearing_email_recipient.hearing_id).not_to eq(original_hearing_email_recipient.hearing_id)
        expect(duplicated_hearing_email_recipient.appeal_id).to eq(original_hearing_email_recipient.appeal_id)
        expect(duplicated_hearing_email_recipient.appeal_type).to eq(original_hearing_email_recipient.appeal_type)
        expect(duplicated_hearing_email_recipient.email_address).to eq(original_hearing_email_recipient.email_address)
        expect(duplicated_hearing_email_recipient.timezone).to eq(original_hearing_email_recipient.timezone)
        expect(duplicated_hearing_email_recipient.type).to eq(original_hearing_email_recipient.type)
      end
    end

    context "when an appeal has latest informal hearing presentation task" do
      it "should duplicate the appeals and latest informal hearing presentation task for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        root_task = create(:root_task, appeal: original_appeal)
        informal_hearing_task = create(
          :colocated_task, :ihp, appeal: original_appeal,
                                 parent: root_task, assigned_at: Date.new(2001, 2, 3)
        )
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }
        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        dup_informal_hearing_task = dup_appeal.tasks.where(type: "IhpColocatedTask").first

        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_appeal.tasks.count).to eq(original_appeal.tasks.count)
        expect(dup_informal_hearing_task.id).not_to eq(informal_hearing_task.id)
        expect(dup_informal_hearing_task.appeal_id).not_to eq(informal_hearing_task.appeal_id)
        expect(dup_informal_hearing_task.assigned_at).to eq(informal_hearing_task.assigned_at)
        expect(dup_informal_hearing_task.assigned_by_id).to eq(informal_hearing_task.assigned_by_id)
        expect(dup_informal_hearing_task.assigned_to_type).to eq(informal_hearing_task.assigned_to_type)
        expect(dup_informal_hearing_task.cancellation_reason).to eq(informal_hearing_task.cancellation_reason)
        expect(dup_informal_hearing_task.cancelled_by_id).to eq(informal_hearing_task.cancelled_by_id)
        expect(dup_informal_hearing_task.closed_at).to eq(informal_hearing_task.closed_at)
        expect(dup_informal_hearing_task.instructions).to eq(informal_hearing_task.instructions)
        expect(dup_informal_hearing_task.parent_id).not_to eq(informal_hearing_task.parent_id)
        expect(dup_informal_hearing_task.placed_on_hold_at).to eq(informal_hearing_task.placed_on_hold_at)
        expect(dup_informal_hearing_task.started_at).to eq(informal_hearing_task.started_at)
        expect(dup_informal_hearing_task.status).to eq(informal_hearing_task.status)
        expect(dup_informal_hearing_task.type).to eq(informal_hearing_task.type)
      end
    end

    context "when an appeal has claimants" do
      it "should duplicate the appeals and claimants for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes"),
          claimants: [create(:claimant)]
        )
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }
        subject { claimant.advanced_on_docket_motion_granted?(original_appeal) }
        AdvanceOnDocketMotion.create_or_update_by_appeal(original_appeal, granted: true, reason: "age")
        expect(subject).to be_truthy
        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        dup_claimant = dup_appeal.claimants.first
        original_claimant = original_appeal.claimants.first
        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_claimant.id).not_to eq(original_claimant.id)
        expect(dup_claimant.decision_review_id).not_to eq(original_claimant.decision_review_id)
        expect(dup_claimant.decision_review_type).to eq(original_claimant.decision_review_type)
        expect(dup_claimant.notes).to eq(original_claimant.notes)
        expect(dup_claimant.participant_id).to eq(original_claimant.participant_id)
        expect(dup_claimant.payee_code).to eq(original_claimant.payee_code)
        expect(dup_claimant.type).to eq(original_claimant.type)
      end
    end

    context "when an appeal has with post intake tasks" do
      it "should duplicate the appeals and with post intake tasks for the same veteran" do
        original_appeal = create(
          :appeal,
          :with_post_intake_tasks,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        # Cancelling one task to cover the cancelling logic of cloning
        original_appeal.tasks.last.update(
          status: Constants.TASK_STATUSES.cancelled,
          cancelled_by_id: regular_user.id,
          closed_at: Time.zone.now
        )
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_appeal.tasks.count).to eq(original_appeal.tasks.count)

        original_appeal.tasks.each do |task|
          task_type = task.type
          dup_task = dup_appeal.tasks.where(type: task_type).first
          expect(dup_task.id).not_to eq(task.id)
          expect(dup_task.appeal_id).not_to eq(task.appeal_id)
          expect(dup_task.assigned_at).to eq(task.assigned_at)
          expect(dup_task.assigned_by_id).to eq(task.assigned_by_id)
          expect(dup_task.assigned_to_type).to eq(task.assigned_to_type)
          expect(dup_task.cancellation_reason).to eq(task.cancellation_reason)
          expect(dup_task.cancelled_by_id).to eq(task.cancelled_by_id)
          expect(dup_task.closed_at).to eq(task.closed_at)
          expect(dup_task.instructions).to eq(task.instructions)
          expect(dup_task.placed_on_hold_at).to eq(task.placed_on_hold_at)
          expect(dup_task.started_at).to eq(task.started_at)
          expect(dup_task.status).to eq(task.status)
          expect(dup_task.type).to eq(task.type)
        end
      end
    end

    context "when an appeal has with cavc remand" do
      it "should duplicate the appeals and with cavc remand for the same veteran" do
        original_appeal = create(
          :appeal, :type_cavc_remand,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }
        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_appeal.cavc_remand.id).not_to eq(original_appeal.cavc_remand.id)
        expect(dup_appeal.cavc_remand.cavc_decision_type).to eq(original_appeal.cavc_remand.cavc_decision_type)
        expect(dup_appeal.cavc_remand.cavc_decision_type).to eq(original_appeal.cavc_remand.cavc_decision_type)
        expect(dup_appeal.cavc_remand.cavc_judge_full_name).to eq(original_appeal.cavc_remand.cavc_judge_full_name)
        expect(dup_appeal.cavc_remand.created_by_id).to eq(original_appeal.cavc_remand.created_by_id)
        expect(dup_appeal.cavc_remand.decision_issue_ids).to match_array(original_appeal.cavc_remand.decision_issue_ids)
        expect(dup_appeal.cavc_remand.federal_circuit).to eq(original_appeal.cavc_remand.federal_circuit)
        expect(dup_appeal.cavc_remand.remand_subtype).to eq(original_appeal.cavc_remand.remand_subtype)
        expect(dup_appeal.cavc_remand.remand_appeal_id).not_to match_array(original_appeal.cavc_remand.remand_appeal_id)
        expect(dup_appeal.cavc_remand.remand_appeal_id).not_to eq(original_appeal.cavc_remand.remand_appeal_id)
        expect(dup_appeal.cavc_remand.represented_by_attorney)
          .to eq(original_appeal.cavc_remand.represented_by_attorney)
        expect(dup_appeal.cavc_remand.source_appeal_id).not_to eq(original_appeal.cavc_remand.source_appeal_id)
        expect(dup_appeal.cavc_remand.updated_by_id).to eq(original_appeal.cavc_remand.updated_by_id)
      end
    end

    context "when an appeal has with appellant substitution" do
      it "should duplicate the appeals and with appellant substitution for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        original_appellant_substitution = create(:appellant_substitution, target_appeal_id: original_appeal.id)
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        dup_appellant_substitution = dup_appeal.appellant_substitution
        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_appellant_substitution.id).not_to eq(original_appellant_substitution.id)
        expect(dup_appellant_substitution.claimant_type).to eq(original_appellant_substitution.claimant_type)
        expect(dup_appellant_substitution.poa_participant_id).to eq(original_appellant_substitution.poa_participant_id)
        expect(dup_appellant_substitution.source_appeal_id).to eq(original_appellant_substitution.source_appeal_id)
        expect(dup_appellant_substitution.substitute_participant_id)
          .to eq(original_appellant_substitution.substitute_participant_id)
        expect(dup_appellant_substitution.target_appeal_id).not_to eq(original_appellant_substitution.target_appeal_id)
        expect(dup_appellant_substitution.substitution_date).to eq(original_appellant_substitution.substitution_date)
      end
    end

    context "when an appeal has with available hearing locations substitution" do
      it "should duplicate the appeals and with available hearing locations for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        create(:available_hearing_locations, :RO17, appeal: original_appeal)
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }
        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)

        available_hearing_locations = dup_appeal.available_hearing_locations.first
        original_available_hearing_location = original_appeal.available_hearing_locations.first

        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_appeal.available_hearing_locations.count).to eq(original_appeal.available_hearing_locations.count)

        expect(available_hearing_locations.id).not_to eq(original_available_hearing_location.id)
        expect(available_hearing_locations.appeal_id).not_to eq(original_available_hearing_location.appeal_id)

        expect(available_hearing_locations.address).to eq(original_available_hearing_location.address)
        expect(available_hearing_locations.appeal_type).to eq(original_available_hearing_location.appeal_type)
        expect(available_hearing_locations.city).to eq(original_available_hearing_location.city)
        expect(available_hearing_locations.classification).to eq(original_available_hearing_location.classification)
        expect(available_hearing_locations.veteran_file_number)
          .to eq(original_available_hearing_location.veteran_file_number)
        expect(available_hearing_locations.facility_id).to eq(original_available_hearing_location.facility_id)
        expect(available_hearing_locations.facility_type).to eq(original_available_hearing_location.facility_type)
        expect(available_hearing_locations.name).to eq(original_available_hearing_location.name)
        expect(available_hearing_locations.state).to eq(original_available_hearing_location.state)
        expect(available_hearing_locations.zip_code).to eq(original_available_hearing_location.zip_code)
        expect(available_hearing_locations.distance).to eq(original_available_hearing_location.distance)
        expect(available_hearing_locations.created_at).to eq(original_available_hearing_location.created_at)
        expect(available_hearing_locations.updated_at).to eq(original_available_hearing_location.updated_at)
      end
    end

    context "when an appeal has with appeal views substitution" do
      it "should duplicate the appeals and with appeal views for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        original_appeal_view = AppealView.create(
          appeal_id: original_appeal.id,
          appeal_type: "Appeal",
          last_viewed_at: Date.new, user_id: regular_user.id
        )
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        dup_appeal_view = dup_appeal.appeal_views.first
        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_appeal.appeal_views.count).to eq(original_appeal.appeal_views.count)
        expect(dup_appeal_view.id).not_to eq(original_appeal_view.id)
        expect(dup_appeal_view.appeal_id).not_to eq(original_appeal_view.appeal_id)
        expect(dup_appeal_view.appeal_type).to eq(original_appeal_view.appeal_type)
        expect(dup_appeal_view.user_id).to eq(original_appeal_view.user_id)
      end
    end

    context "when an appeal has with docket switch" do
      it "should duplicate the appeals and with docket switch for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        original_appeal.docket_switch = create(:docket_switch)
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        dup_docket_switch = dup_appeal.docket_switch
        original_docket_switch = original_appeal.docket_switch

        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)

        expect(dup_docket_switch.id).not_to eq(original_docket_switch.id)
        expect(dup_docket_switch.new_docket_stream_id).not_to eq(original_docket_switch.new_docket_stream_id)
        expect(dup_docket_switch.disposition).to eq(original_docket_switch.disposition)
        expect(dup_docket_switch.docket_type).to eq(original_docket_switch.docket_type)
        expect(dup_docket_switch.granted_request_issue_ids).to eq(original_docket_switch.granted_request_issue_ids)
        expect(dup_docket_switch.old_docket_stream_id).to eq(original_docket_switch.old_docket_stream_id)
        expect(dup_docket_switch.receipt_date).to eq(original_docket_switch.receipt_date)
        expect(dup_docket_switch.task_id).to eq(original_docket_switch.task_id)
        expect(dup_docket_switch.updated_at).to eq(original_docket_switch.updated_at)
        expect(dup_docket_switch.created_at).to eq(original_docket_switch.created_at)
      end
    end

    context "when an appeal has with ihp draft" do
      it "should duplicate the appeals and with  ihp draft for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        IhpDraft.create(
          appeal: original_appeal,
          organization: create(:organization),
          path: "\\\\vacoappbva3.dva.va.gov\\DMDI$\\VBMS Paperless IHPs\\AML\\AMA IHPs\\VetName 12345.pdf"
        )
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        original_ihp_draft = IhpDraft.where(appeal: original_appeal).first
        dup_ihp_draft = IhpDraft.where(appeal: dup_appeal).first
        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_ihp_draft.id).not_to eq(original_ihp_draft.id)
        expect(dup_ihp_draft.appeal_id).not_to eq(original_ihp_draft.appeal_id)
        expect(dup_ihp_draft.organization_id).to eq(original_ihp_draft.organization_id)
        expect(dup_ihp_draft.path).to eq(original_ihp_draft.path)
      end
    end

    context "when an appeal has with work mode" do
      it "should duplicate the appeals and with work mode for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        original_work_mode = WorkMode.create(appeal_id: original_appeal.id, appeal_type: "Appeal")
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_appeal.appeal_views.count).to eq(original_appeal.appeal_views.count)
        expect(original_work_mode.id).not_to eq(dup_appeal.work_mode.id)
        expect(original_work_mode.appeal_id).not_to eq(dup_appeal.work_mode.appeal_id)
        expect(original_work_mode.appeal_type).to eq(dup_appeal.work_mode.appeal_type)
        expect(original_work_mode.overtime).to eq(dup_appeal.work_mode.overtime)
      end
    end

    context "when an appeal has with claims folder search" do
      it "should duplicate the appeals and with claims folder search for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        ClaimsFolderSearch.create(
          appeal_id: original_appeal.id,
          appeal_type: "Appeal",
          query: "test query here",
          user_id: regular_user.id
        )
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        original_cfs = original_appeal.claims_folder_searches.first
        dup_cfs = dup_appeal.claims_folder_searches.first
        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_appeal.claims_folder_searches.count).to eq(original_appeal.claims_folder_searches.count)
        expect(original_cfs.id).not_to eq(dup_cfs.id)
        expect(original_cfs.appeal_id).not_to eq(dup_cfs.appeal_id)
        expect(original_cfs.appeal_type).to eq(dup_cfs.appeal_type)
        expect(original_cfs.query).to eq(dup_cfs.query)
        expect(original_cfs.user_id).to eq(dup_cfs.user_id)
      end
    end

    context "when an appeal has with nod date update" do
      it "should duplicate the appeals and with nod date update for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        NodDateUpdate.create(
          appeal_id: original_appeal.id,
          change_reason: "entry_error",
          new_date: Date.new, old_date: Date.new, user_id: regular_user.id
        )
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        original_ndu = original_appeal.nod_date_updates.first
        dup_ndu = dup_appeal.nod_date_updates.first
        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_appeal.nod_date_updates.count).to eq(original_appeal.nod_date_updates.count)
        expect(original_ndu.id).not_to eq(dup_ndu.id)
        expect(original_ndu.appeal_id).not_to eq(dup_ndu.appeal_id)
        expect(original_ndu.change_reason).to eq(dup_ndu.change_reason)
        expect(original_ndu.new_date).to eq(dup_ndu.new_date)
        expect(original_ndu.old_date).to eq(dup_ndu.old_date)
        expect(original_ndu.user_id).to eq(dup_ndu.user_id)
      end
    end

    context "when an appeal has with record synced by job" do
      it "should duplicate the appeals and with record synced by job for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        RecordSyncedByJob.create(
          error: "no error",
          record_id: original_appeal.id,
          record_type: "Appeal", sync_job_name: "job name here"
        )
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        original_rsb_job = original_appeal.record_synced_by_job.first
        dup_rsb_job = dup_appeal.record_synced_by_job.first
        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_appeal.record_synced_by_job.count).to eq(original_appeal.record_synced_by_job.count)
        expect(original_rsb_job.id).not_to eq(dup_rsb_job.id)
        expect(original_rsb_job.record_id).not_to eq(dup_rsb_job.record_id)
        expect(original_rsb_job.record_type).to eq(dup_rsb_job.record_type)
        expect(original_rsb_job.error).to eq(dup_rsb_job.error)
        expect(original_rsb_job.sync_job_name).to eq(dup_rsb_job.sync_job_name)
      end
    end

    context "when an appeal has with special issue list" do
      it "should duplicate the appeals and with special issue list for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        SpecialIssueList.create(appeal_id: original_appeal.id, appeal_type: "Appeal", blue_water: true)
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        original_ndu = original_appeal.special_issue_list
        dup_ndu = dup_appeal.special_issue_list
        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(original_ndu.id).not_to eq(dup_ndu.id)
        expect(original_ndu.appeal_id).not_to eq(dup_ndu.appeal_id)
        expect(original_ndu.blue_water).to eq(dup_ndu.blue_water)
        expect(original_ndu.burn_pit).to eq(dup_ndu.burn_pit)
        expect(original_ndu.contaminated_water_at_camp_lejeune).to eq(dup_ndu.contaminated_water_at_camp_lejeune)
        expect(original_ndu.dic_death_or_accrued_benefits_united_states)
          .to eq(dup_ndu.dic_death_or_accrued_benefits_united_states)
        expect(original_ndu.education_gi_bill_dependents_educational_assistance_scholars)
          .to eq(dup_ndu.education_gi_bill_dependents_educational_assistance_scholars)
        expect(original_ndu.foreign_claim_compensation_claims_dual_claims_appeals)
          .to eq(dup_ndu.foreign_claim_compensation_claims_dual_claims_appeals)
        expect(original_ndu.foreign_pension_dic_all_other_foreign_countries)
          .to eq(dup_ndu.foreign_pension_dic_all_other_foreign_countries)
        expect(original_ndu.foreign_pension_dic_mexico_central_and_south_america_caribb)
          .to eq(dup_ndu.foreign_pension_dic_mexico_central_and_south_america_caribb)
        expect(original_ndu.hearing_including_travel_board_video_conference)
          .to eq(dup_ndu.hearing_including_travel_board_video_conference)
        expect(original_ndu.home_loan_guaranty).to eq(dup_ndu.home_loan_guaranty)
        expect(original_ndu.incarcerated_veterans).to eq(dup_ndu.incarcerated_veterans)
        expect(original_ndu.insurance).to eq(dup_ndu.insurance)
        expect(original_ndu.manlincon_compliance).to eq(dup_ndu.manlincon_compliance)
        expect(original_ndu.manlincon_compliance).to eq(dup_ndu.manlincon_compliance)
        expect(original_ndu.military_sexual_trauma).to eq(dup_ndu.military_sexual_trauma)
        expect(original_ndu.mustard_gas).to eq(dup_ndu.mustard_gas)
        expect(original_ndu.national_cemetery_administration).to eq(dup_ndu.national_cemetery_administration)
        expect(original_ndu.no_special_issues).to eq(dup_ndu.no_special_issues)
        expect(original_ndu.nonrating_issue).to eq(dup_ndu.nonrating_issue)
        expect(original_ndu.pension_united_states).to eq(dup_ndu.pension_united_states)
        expect(original_ndu.private_attorney_or_agent).to eq(dup_ndu.private_attorney_or_agent)
        expect(original_ndu.radiation).to eq(dup_ndu.radiation)
        expect(original_ndu.rice_compliance).to eq(dup_ndu.rice_compliance)
        expect(original_ndu.spina_bifida).to eq(dup_ndu.spina_bifida)
        expect(original_ndu.us_court_of_appeals_for_veterans_claims)
          .to eq(dup_ndu.us_court_of_appeals_for_veterans_claims)
        expect(original_ndu.us_territory_claim_american_samoa_guam_northern_mariana_isla)
          .to eq(dup_ndu.us_territory_claim_american_samoa_guam_northern_mariana_isla)
        expect(original_ndu.us_territory_claim_philippines).to eq(dup_ndu.us_territory_claim_philippines)
        expect(original_ndu.us_territory_claim_puerto_rico_and_virgin_islands)
          .to eq(dup_ndu.us_territory_claim_puerto_rico_and_virgin_islands)
        expect(original_ndu.vamc).to eq(dup_ndu.vamc)
        expect(original_ndu.vocational_rehab).to eq(dup_ndu.vocational_rehab)
        expect(original_ndu.waiver_of_overpayment).to eq(dup_ndu.waiver_of_overpayment)
      end
    end

    context "when an appeal has with power of attorney" do
      it "should duplicate the appeals and with power of attorney for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        original_power_of_attorney = original_appeal.power_of_attorney
        dup_power_of_attorney = dup_appeal.power_of_attorney
        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_appeal.record_synced_by_job.count).to eq(original_appeal.record_synced_by_job.count)
        expect(original_power_of_attorney.id).to eq(dup_power_of_attorney.id)
        expect(original_power_of_attorney.authzn_poa_access_ind).to eq(dup_power_of_attorney.authzn_poa_access_ind)
        expect(original_power_of_attorney.claimant_participant_id).to eq(dup_power_of_attorney.claimant_participant_id)
        expect(original_power_of_attorney.file_number).to eq(dup_power_of_attorney.file_number)
        expect(original_power_of_attorney.legacy_poa_cd).to eq(dup_power_of_attorney.legacy_poa_cd)
        expect(original_power_of_attorney.poa_participant_id).to eq(dup_power_of_attorney.poa_participant_id)
        expect(original_power_of_attorney.representative_name).to eq(dup_power_of_attorney.representative_name)
        expect(original_power_of_attorney.representative_type).to eq(dup_power_of_attorney.representative_type)
      end
    end

    context "when an appeal has with request issues update" do
      it "should duplicate the appeals and with request issues update for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes")
        )
        create(
          :supplemental_claim,
          veteran_file_number: original_appeal.veteran_file_number,
          legacy_opt_in_approved: false, veteran_is_not_claimant: false,
          decision_review_remanded_id: original_appeal.id,
          decision_review_remanded_type: "Appeal"
        )
        original_riu = RequestIssuesUpdate.create(
          review: original_appeal.remand_supplemental_claims.first,
          user: regular_user,
          before_request_issue_ids: [original_appeal.request_issues.last.id],
          after_request_issue_ids: [original_appeal.request_issues.last.id],
          attempted_at: Time.zone.now, last_submitted_at: Time.zone.now
        )
        original_appeal.request_issues_updates = [original_riu]
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        original_request_issues_update = original_appeal.request_issues_updates.first
        dup_request_issues_update = dup_appeal.request_issues_updates.first
        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.request_issues.count).to eq(original_appeal.request_issues.count)
        expect(dup_appeal.request_issues_updates.count).to eq(original_appeal.request_issues_updates.count)
        expect(original_request_issues_update.id).not_to eq(dup_request_issues_update.id)
        expect(original_request_issues_update.after_request_issue_ids)
          .to match_array(dup_request_issues_update.after_request_issue_ids)
        expect(original_request_issues_update.before_request_issue_ids)
          .to match_array(dup_request_issues_update.before_request_issue_ids)
        expect(original_request_issues_update.corrected_request_issue_ids)
          .to eq(dup_request_issues_update.corrected_request_issue_ids)
        expect(original_request_issues_update.edited_request_issue_ids)
          .to eq(dup_request_issues_update.edited_request_issue_ids)
        expect(original_request_issues_update.review_id).not_to eq(dup_request_issues_update.review_id)
        expect(original_request_issues_update.review_type).to eq(dup_request_issues_update.review_type)
        expect(original_request_issues_update.user_id).to eq(dup_request_issues_update.user_id)
        expect(original_request_issues_update.withdrawn_request_issue_ids)
          .to eq(dup_request_issues_update.withdrawn_request_issue_ids)
      end
    end

    context "if a request issue has already been copied (status of 'on_hold')" do
      it "should throw an error and not duplicate the appeal" do
        original_appeal = create(
          :appeal, #:with_decision_issue,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes"),
          decision_issues: create_list(:decision_issue, 1)
        )
        create(
          :request_decision_issue,
          request_issue: original_appeal.request_issues.first,
          decision_issue: original_appeal.decision_issues.first
        )
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save

        expect do
          dup_appeal.finalize_split_appeal(
            original_appeal,
            params
          ).to raise_error(Appeal::IssueAlreadyDuplicated)
        end
        # the appeal is not duplicated
        expect(Appeal.where(stream_docket_number: appeal.stream_docket_number).count).to eq(1)
      end
    end

    context "when an appeal has numerous decision issues" do
      it "should duplicate the appeals and numerous decision issues for the same veteran" do
        original_appeal = create(
          :appeal,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes"),
          decision_issues: create_list(:decision_issue, 1)
        )
        create(
          :request_decision_issue,
          request_issue: original_appeal.request_issues.first,
          decision_issue: original_appeal.decision_issues.first
        )
        all_request_issues = original_appeal.request_issues.ids.map(&:to_s)

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: all_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }

        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        original_decision_issue = original_appeal.decision_issues.first
        dup_decision_issue = dup_appeal.decision_issues.first

        expect(dup_appeal.id).not_to eq(original_appeal.id)
        expect(dup_appeal.uuid).not_to eq(original_appeal.uuid)
        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.decision_issues.count).to eq(original_appeal.decision_issues.count)
        expect(original_decision_issue.id).not_to eq(dup_decision_issue.id)
        expect(original_decision_issue.decision_review_id).not_to eq(dup_decision_issue.decision_review_id)
        expect(original_decision_issue.benefit_type).to eq(dup_decision_issue.benefit_type)
        expect(original_decision_issue.decision_review_type).to eq(dup_decision_issue.decision_review_type)
        expect(original_decision_issue.decision_text).to eq(dup_decision_issue.decision_text)
        expect(original_decision_issue.deleted_at).to eq(dup_decision_issue.deleted_at)
        expect(original_decision_issue.description).to eq(dup_decision_issue.description)
        expect(original_decision_issue.diagnostic_code).to eq(dup_decision_issue.diagnostic_code)
        expect(original_decision_issue.end_product_last_action_date)
          .to eq(dup_decision_issue.end_product_last_action_date)
        expect(original_decision_issue.participant_id).to eq(dup_decision_issue.participant_id)
        expect(original_decision_issue.percent_number).to eq(dup_decision_issue.percent_number)
        expect(original_decision_issue.rating_issue_reference_id).to eq(dup_decision_issue.rating_issue_reference_id)
        expect(original_decision_issue.rating_profile_date).to eq(dup_decision_issue.rating_profile_date)
        expect(original_decision_issue.rating_promulgation_date).to eq(dup_decision_issue.rating_promulgation_date)
        expect(original_decision_issue.subject_text).to eq(dup_decision_issue.subject_text)
      end

      it "duplicates the request issues selected, sets the original issue to 'on hold' and not active" do
        original_appeal = create(
          :appeal, #:with_decision_issue,
          request_issues: create_list(:request_issue, 4, :nonrating, notes: "test notes"),
          decision_issues: create_list(:decision_issue, 1)
        )
        create(
          :request_decision_issue,
          request_issue: original_appeal.request_issues.first,
          decision_issue: original_appeal.decision_issues.first
        )
        selected_request_issues = [original_appeal.request_issues.first.id.to_s]

        params = {
          appeal_id: original_appeal.id,
          appeal_split_issues: selected_request_issues,
          split_reason: "Other",
          split_other_reason: "Some Other Reason",
          user_css_id: regular_user.css_id
        }
        dup_appeal = original_appeal.amoeba_dup
        dup_appeal.save
        dup_appeal.finalize_split_appeal(original_appeal, params)
        original_decision_issue = original_appeal.decision_issues.first
        dup_decision_issue = dup_appeal.decision_issues.first
        original_appeal.reload
        expect(dup_appeal.request_issues.count).not_to eq(original_appeal.request_issues.count)
        expect(dup_appeal.request_issues.count).to eq(1)
        expect(dup_appeal.request_issues.active.count).to eq(1)
        expect(original_appeal.request_issues.active.count).to eq(3)
        expect(dup_appeal.request_issues.first.split_issue_status).to eq("in_progress")
        expect(original_appeal.request_issues.first.split_issue_status).to eq("on_hold")

        expect(dup_appeal.veteran_file_number).to eq(original_appeal.veteran_file_number)
        expect(dup_appeal.decision_issues.count).to eq(original_appeal.decision_issues.count)
        expect(original_decision_issue.id).not_to eq(dup_decision_issue.id)
        expect(original_decision_issue.decision_review_id).not_to eq(dup_decision_issue.decision_review_id)
        expect(original_decision_issue.benefit_type).to eq(dup_decision_issue.benefit_type)
        expect(original_decision_issue.decision_review_type).to eq(dup_decision_issue.decision_review_type)
        expect(original_decision_issue.decision_text).to eq(dup_decision_issue.decision_text)
        expect(original_decision_issue.deleted_at).to eq(dup_decision_issue.deleted_at)
        expect(original_decision_issue.description).to eq(dup_decision_issue.description)
        expect(original_decision_issue.diagnostic_code).to eq(dup_decision_issue.diagnostic_code)
        expect(original_decision_issue.end_product_last_action_date)
          .to eq(dup_decision_issue.end_product_last_action_date)
        expect(original_decision_issue.participant_id).to eq(dup_decision_issue.participant_id)
        expect(original_decision_issue.percent_number).to eq(dup_decision_issue.percent_number)
        expect(original_decision_issue.rating_issue_reference_id).to eq(dup_decision_issue.rating_issue_reference_id)
        expect(original_decision_issue.rating_profile_date).to eq(dup_decision_issue.rating_profile_date)
        expect(original_decision_issue.rating_promulgation_date).to eq(dup_decision_issue.rating_promulgation_date)
        expect(original_decision_issue.subject_text).to eq(dup_decision_issue.subject_text)
      end
    end
  end
end
