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

    context "when the appeal has vha issues" do
      let(:request_issues) do
        [
          create(:request_issue, benefit_type: "vha"),
        ]
      end

      before do
        FeatureToggle.enable!(:vha_predocket_appeals)
      end

      after do
        FeatureToggle.disable!(:vha_predocket_appeals)
      end

      it "does not create business line tasks" do
        expect(VeteranRecordRequest).to_not receive(:create!)

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

    context "if the only active case is a RootTask" do
      let(:appeal) { create(:appeal) }

      before do
        create(:root_task, :in_progress, appeal: appeal)
      end

      it "returns Case storage" do
        expect(appeal.assigned_to_location).to eq(COPY::CASE_LIST_TABLE_CASE_STORAGE_LABEL)
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
        it "returns Case storage because it does not include nonactionable tasks in its determinations" do
          expect(appeal.assigned_to_location).to eq(COPY::CASE_LIST_TABLE_CASE_STORAGE_LABEL)
        end
      end

      describe "when there is an actionable task with an assignee", skip: "flake" do
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
        create(:ama_attorney_task, parent: judge_decision_review_task, assigned_to: attorney2, appeal: appeal)
      end

      subject { appeal.assigned_attorney }

      it "returns the assigned attorney for the most recent non-cancelled AttorneyTask" do
        expect(subject).to eq attorney2
      end

      it "should know the right assigned attorney with a cancelled task" do
        task2.cancelled!
        expect(subject).to eq attorney
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
          subject.receipt_date + DirectReviewDocket::DAYS_TO_DECISION_GOAL.days
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
end
