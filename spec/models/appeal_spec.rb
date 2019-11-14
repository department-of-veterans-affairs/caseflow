# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe Appeal, :all_dbs do
  include IntakeHelpers

  let!(:appeal) { create(:appeal) }

  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
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
    let(:task1) { create(:ama_attorney_task, appeal: appeal) }
    let(:task2) { create(:ama_attorney_task, appeal: appeal) }
    let!(:attorney_case_review1) { create(:attorney_case_review, task: task1, created_at: 2.days.ago) }
    let!(:attorney_case_review2) { create(:attorney_case_review, task: task2, created_at: 1.day.ago) }

    subject { appeal.latest_attorney_case_review }

    it "returns the latest record" do
      expect(subject).to eq attorney_case_review2
    end
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

      it "returns a docket number if receipt_date is defined" do
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

  context "#advanced_on_docket?" do
    context "when a claimant is advanced_on_docket?" do
      let(:appeal) do
        create(:appeal, claimants: [create(:claimant, :advanced_on_docket_due_to_age)])
      end

      it "returns true" do
        expect(appeal.advanced_on_docket?).to eq(true)
      end
    end

    context "when no claimant is advanced_on_docket?" do
      let(:appeal) do
        create(:appeal)
      end

      it "returns false" do
        expect(appeal.advanced_on_docket?).to eq(false)
      end
    end
  end

  context "#find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id" do
    context "with a uuid (AMA appeal id)" do
      let(:veteran_file_number) { "64205050" }

      let(:appeal) do
        create(:appeal, veteran_file_number: veteran_file_number)
      end

      it "finds the appeal" do
        expect(Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(appeal.uuid)).to \
          eq(appeal)
      end

      it "returns RecordNotFound for a non-existant one" do
        made_up_uuid = "11111111-aaaa-bbbb-CCCC-999999999999"
        expect { Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(made_up_uuid) }.to \
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
        expect(Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(legacy_appeal.vacols_id)).to \
          eq(legacy_appeal)
      end

      it "returns RecordNotFound for a non-existant one" do
        made_up_non_uuid = "9876543"
        expect do
          Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(made_up_non_uuid)
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
        expect(subject).to eq appeal.claimants.first.first_name
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
        participant_id: "9876"
      )
    end

    before do
      allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
        .with([participant_id_with_pva]).and_return(
          participant_id_with_pva => {
            representative_name: "PARALYZED VETERANS OF AMERICA, INC.",
            representative_type: "POA National Organization",
            participant_id: "9876"
          }
        )
      allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
        .with([participant_id_with_aml]).and_return(
          participant_id_with_aml => {
            representative_name: "AMERICAN LEGION",
            representative_type: "POA National Organization",
            participant_id: "54321"
          }
        )
    end

    context "#power_of_attorney" do
      it "returns the first claimant's power of attorney" do
        expect(appeal.power_of_attorney.representative_name).to eq("PARALYZED VETERANS OF AMERICA, INC.")
      end
    end

    context "#power_of_attorneys" do
      it "returns all claimants power of attorneys" do
        expect(appeal.power_of_attorneys[0].representative_name).to eq("PARALYZED VETERANS OF AMERICA, INC.")
        expect(appeal.power_of_attorneys[1].representative_name).to eq("AMERICAN LEGION")
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
                 create(:request_issue, benefit_type: :fiduciary),
                 create(:request_issue, benefit_type: :compensation),
                 create(:request_issue, :unidentified)
               ])
      end

      it "creates root task and veteran record request task" do
        expect(VeteranRecordRequest).to receive(:create!).once

        subject
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

    context "if there are TrackVeteranTasks" do
      let!(:appeal) { create(:appeal) }
      let!(:root_task) { create(:root_task, :in_progress, appeal: appeal) }

      before do
        create(:track_veteran_task, :in_progress, appeal: appeal)
      end

      it "does not include TrackVeteranTasks in its determinations" do
        expect(appeal.assigned_to_location).to eq(COPY::CASE_LIST_TABLE_CASE_STORAGE_LABEL)
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
        create(:generic_task, assigned_to: organization, appeal: appeal_organization, parent: organization_root_task)

        user_root_task = create(:root_task, appeal: appeal_user)
        create(:generic_task, assigned_to: user, appeal: appeal_user, parent: user_root_task)

        on_hold_root = create(:root_task, appeal: appeal_on_hold, updated_at: today - 1)
        create(:generic_task, :on_hold, appeal: appeal_on_hold, parent: on_hold_root, updated_at: today + 1)
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
      let!(:task) { create(:ama_attorney_task, assigned_to: attorney, appeal: appeal, created_at: 1.day.ago) }
      let!(:task2) { create(:ama_attorney_task, assigned_to: attorney2, appeal: appeal) }

      subject { appeal.assigned_attorney }

      it "returns the assigned attorney for the most recent non-cancelled AttorneyTask" do
        expect(subject).to eq attorney2
      end

      it "should know the right assigned attorney with a cancelled task" do
        task2.update(status: "cancelled")
        expect(subject).to eq attorney
      end
    end

    context ".assigned_judge" do
      let!(:judge) { create(:user) }
      let!(:judge2) { create(:user) }
      let!(:appeal) { create(:appeal) }
      let!(:task) { create(:ama_judge_task, assigned_to: judge, appeal: appeal, created_at: 1.day.ago) }
      let!(:task2) { create(:ama_judge_task, assigned_to: judge2, appeal: appeal) }

      subject { appeal.assigned_judge }

      it "returns the assigned judge for the most recent non-cancelled JudgeTask" do
        expect(subject).to eq judge2
      end

      it "should know the right assigned judge with a cancelled tasks" do
        task2.update(status: "cancelled")
        expect(subject).to eq judge
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

  context "#program" do
    subject { appeal.program }

    let(:benefit_type1) { "compensation" }
    let(:benefit_type2) { "pension" }
    let(:appeal) { create(:appeal, request_issues: [request_issue]) }
    let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }
    let(:request_issue2) { create(:request_issue, benefit_type: benefit_type1) }
    let(:request_issue3) { create(:request_issue, benefit_type: benefit_type2) }

    context "appeal has one request issue" do
      it { is_expected.to eq benefit_type1 }
    end

    context "appeal has multiple request issues with same benefit type" do
      let(:appeal) { create(:appeal, request_issues: [request_issue, request_issue2]) }

      it { is_expected.to eq benefit_type1 }
    end

    context "appeal has multiple request issue with different benefit_types" do
      let(:appeal) { create(:appeal, request_issues: [request_issue, request_issue2, request_issue3]) }

      it { is_expected.to eq "multiple" }
    end
  end

  context "#active_status" do
    subject { appeal.active_status? }

    context "there are in-progress tasks" do
      let(:appeal) { create(:appeal) }

      before do
        create_list(:task, 3, :in_progress, type: RootTask.name, appeal: appeal)
      end

      it "appeal is active" do
        expect(subject).to eq(true)
      end
    end

    context "has an effectuation ep that is active" do
      let(:appeal) { create(:appeal) }
      let(:decision_document) { create(:decision_document, appeal: appeal) }
      let(:ep_status) { "PEND" }
      let!(:effectuation_ep) { create(:end_product_establishment, source: decision_document, synced_status: ep_status) }

      it "appeal is active" do
        expect(subject).to eq(true)
      end

      context "effection ep cleared" do
        let(:ep_status) { "CLR" }

        it "appeal is not active" do
          expect(subject).to eq(false)
        end
      end
    end

    context "has an open remanded supplemental claim" do
      let(:appeal) { create(:appeal) }
      let(:remanded_sc) { create(:supplemental_claim, decision_review_remanded: appeal) }
      let(:ep_status) { "PEND" }
      let!(:remanded_ep) { create(:end_product_establishment, source: remanded_sc, synced_status: ep_status) }

      it "appeal is active" do
        expect(subject).to eq(true)
      end

      context "remanded supplemental_claim is closed" do
        let(:ep_status) { "CLR" }

        it "appeal is not active" do
          expect(subject).to eq(false)
        end
      end
    end
  end

  describe "#status" do
    it "returns BVAAppealStatus object" do
      expect(appeal.status).to be_a(BVAAppealStatus)
      expect(appeal.status.to_s).to eq("UNKNOWN") # zero tasks
    end
  end

  context "#location" do
    subject { appeal.location }

    context "has an active effectuation ep" do
      let(:appeal) { create(:appeal) }
      let(:decision_document) { create(:decision_document, appeal: appeal) }
      let(:ep_status) { "PEND" }
      let!(:effectuation_ep) { create(:end_product_establishment, source: decision_document, synced_status: ep_status) }

      it "is at aoj" do
        expect(subject).to eq("aoj")
      end

      context "effection ep cleared" do
        let(:ep_status) { "CLR" }

        it "is at bva" do
          expect(subject).to eq("bva")
        end
      end
    end

    context "has an open remanded supplemental claim" do
      let(:appeal) { create(:appeal) }
      let(:remanded_sc) { create(:supplemental_claim, decision_review_remanded: appeal) }
      let(:ep_status) { "PEND" }
      let!(:remanded_ep) { create(:end_product_establishment, source: remanded_sc, synced_status: ep_status) }

      it "is at aoj" do
        expect(subject).to eq("aoj")
      end

      context "remanded supplemental_claim is closed" do
        let(:ep_status) { "CLR" }

        it "is at bva" do
          expect(subject).to eq("bva")
        end
      end
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

  context "#events" do
    let(:receipt_date) { Constants::DATES["AMA_ACTIVATION_TEST"].to_date + 1 }
    let!(:appeal) { create(:appeal, receipt_date: receipt_date) }
    let!(:decision_date) { receipt_date + 130.days }
    let!(:decision_document) { create(:decision_document, appeal: appeal, decision_date: decision_date) }
    let(:judge) { create(:user) }
    let(:judge_task_created_date) { receipt_date + 10 }
    let!(:judge_review_task) do
      create(:ama_judge_decision_review_task, :completed,
             assigned_to: judge, appeal: appeal, created_at: judge_task_created_date)
    end
    let!(:judge_quality_review_task) do
      create(:ama_judge_quality_review_task, :completed,
             assigned_to: judge, appeal: appeal, created_at: judge_task_created_date + 2.days)
    end

    context "decision, no remand and an effectuation" do
      let!(:decision_issue) { create(:decision_issue, decision_review: appeal, caseflow_decision_date: decision_date) }
      let(:ep_cleared_date) { receipt_date + 150.days }
      let!(:effectuation_ep) do
        create(:end_product_establishment,
               :cleared, source: decision_document, last_synced_at: ep_cleared_date)
      end

      it "has an nod event, judge assigned event, decision event and effectation event" do
        events = appeal.events
        nod_event = events.find { |e| e.type == :ama_nod }
        expect(nod_event.date.to_date).to eq(receipt_date.to_date)

        judge_assigned_event = events.find { |e| e.type == :distributed_to_vlj }
        expect(judge_assigned_event.date.to_date).to eq(judge_task_created_date.to_date)

        decision_event = events.find { |e| e.type == :bva_decision }
        expect(decision_event.date.to_date).to eq(decision_date.to_date)

        effectuation_event = events.find { |e| e.type == :bva_decision_effectuation }
        expect(effectuation_event.date.to_date).to eq(ep_cleared_date.to_date)
      end
    end

    context "decision with a remand and an effectuation" do
      # the effectuation
      let!(:decision_issue) { create(:decision_issue, decision_review: appeal, caseflow_decision_date: decision_date) }
      let(:ep_cleared_date) { receipt_date + 150.days }
      let!(:effectuation_ep) do
        create(:end_product_establishment,
               :cleared, source: decision_document, last_synced_at: ep_cleared_date)
      end
      # the remand
      let!(:remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal, disposition: "remanded", benefit_type: "compensation")
      end
      let(:remanded_sc) { create(:supplemental_claim, decision_review_remanded: appeal) }
      let(:remanded_ep_clr_date) { receipt_date + 200.days }
      let!(:remanded_ep) { create(:end_product_establishment, :cleared, source: remanded_sc) }
      let!(:remanded_sc_decision_issue) do
        create(:decision_issue,
               decision_review: remanded_sc,
               end_product_last_action_date: remanded_ep_clr_date)
      end

      it "has nod event, judge assigned event, decision event, remand decision event" do
        events = appeal.events
        nod_event = events.find { |e| e.type == :ama_nod }
        expect(nod_event.date.to_date).to eq(receipt_date.to_date)

        judge_assigned_event = events.find { |e| e.type == :distributed_to_vlj }
        expect(judge_assigned_event.date.to_date).to eq(judge_task_created_date.to_date)

        decision_event = events.find { |e| e.type == :bva_decision }
        expect(decision_event.date.to_date).to eq(decision_date.to_date)

        remand_decision_event = events.find { |e| e.type == :dta_decision }
        expect(remand_decision_event.date.to_date).to eq(remanded_ep_clr_date.to_date)

        effectuation_event = events.find { |e| e.type == :bva_decision_effectuation }
        expect(effectuation_event).to be_nil
      end
    end
  end

  context "#docket_hash" do
    let(:october_docket_date) { Time.new("2018", "10", "01").utc }
    let(:receipt_date) { october_docket_date + 20.days }

    let(:decision_date1) { receipt_date - 50.days }
    let(:request_issue1) { create(:request_issue, :nonrating, decision_date: decision_date1) }

    let(:decision_date2) { receipt_date - 60.days }
    let(:request_issue2) { create(:request_issue, :nonrating, decision_date: decision_date2) }

    let(:decision_date3) { receipt_date - 100.days }
    let(:removed_request_issue) do
      create(
        :request_issue,
        :nonrating,
        decision_date: decision_date3,
        closed_at: receipt_date
      )
    end

    let(:docket_type) { Constants.AMA_DOCKETS.direct_review }
    let!(:appeal) do
      create(:appeal,
             receipt_date: receipt_date,
             request_issues: [request_issue1, request_issue2, removed_request_issue],
             docket_type: docket_type)
    end

    let!(:root_task) { create(:root_task, :in_progress, appeal: appeal) }

    context "all request issues have a decision or promulgation date" do
      it "is direct review, in Oct month, has docket switch deadline and is eligible to switch" do
        docket = appeal.docket_hash

        expect(docket).not_to be_nil
        expect(docket[:type]).to eq("directReview")
        expect(docket[:month]).to eq(october_docket_date.to_date)
        expect(docket[:switchDueDate]).to eq((decision_date2 + 365.days).to_date)
        expect(docket[:eligibleToSwitch]).to eq(true)
      end
    end

    context "cannot get decision or promulgation date for an open request issue" do
      let(:decision_date1) { nil }
      let(:decision_date3) { nil }

      it "is direct review, in Oct month, has no switch deadline and is not eligible to switch" do
        docket = appeal.docket_hash

        expect(docket).not_to be_nil
        expect(docket[:type]).to eq("directReview")
        expect(docket[:month]).to eq(october_docket_date.to_date)
        expect(docket[:switchDueDate]).to be_nil
        expect(docket[:eligibleToSwitch]).to eq(false)
      end
    end
  end

  context "#alerts" do
    subject { appeal.alerts }
    let(:receipt_date) { Time.zone.today - 10.days }
    let!(:appeal) { create(:appeal, :hearing_docket, receipt_date: receipt_date) }

    context "has a remand and effectuation tracked in VBMS" do
      # the effectuation
      let(:decision_date) { receipt_date + 30.days }
      let!(:decision_document) { create(:decision_document, appeal: appeal, decision_date: decision_date) }
      let!(:decision_issue) do
        create(:decision_issue,
               decision_review: appeal, disposition: "allowed", caseflow_decision_date: decision_date)
      end
      let(:effectuation_ep_cleared_date) { receipt_date + 250.days }
      let!(:effectuation_ep) do
        create(:end_product_establishment,
               :cleared, source: decision_document, last_synced_at: effectuation_ep_cleared_date)
      end
      # the remand
      let!(:remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal,
               disposition: "remanded",
               benefit_type: "compensation",
               caseflow_decision_date: decision_date)
      end
      let!(:remanded_sc) { create(:supplemental_claim, decision_review_remanded: appeal) }
      let(:remanded_ep_clr_date) { receipt_date + 200.days }
      let!(:remanded_ep) { create(:end_product_establishment, :cleared, source: remanded_sc) }
      let!(:remanded_sc_decision_issue) do
        create(:decision_issue,
               decision_review: remanded_sc,
               end_product_last_action_date: remanded_ep_clr_date)
      end

      it "has 3 ama_post_decision alerts" do
        expect(subject.count).to eq(3)

        expect(subject[0][:type]).to eq("ama_post_decision")
        expect(subject[0][:details][:availableOptions]).to eq(%w[supplemental_claim cavc])
        expect(subject[0][:details][:dueDate].to_date).to eq((decision_date + 365.days).to_date)
        expect(subject[0][:details][:cavcDueDate].to_date).to eq((decision_date + 120.days).to_date)

        expect(subject[1][:type]).to eq("ama_post_decision")
        expect(subject[1][:details][:availableOptions]).to eq(%w[supplemental_claim higher_level_review appeal])
        expect(subject[1][:details][:dueDate].to_date).to eq((remanded_ep_clr_date + 365.days).to_date)
        expect(subject[1][:details][:cavcDueDate].to_date).to eq((remanded_ep_clr_date + 120.days).to_date)

        expect(subject[2][:type]).to eq("ama_post_decision")
        expect(subject[2][:details][:availableOptions]).to eq(%w[supplemental_claim cavc])
        expect(subject[2][:details][:dueDate].to_date).to eq((effectuation_ep_cleared_date + 365.days).to_date)
        expect(subject[2][:details][:cavcDueDate].to_date).to eq((effectuation_ep_cleared_date + 120.days).to_date)
      end
    end

    context "has an open evidence submission task" do
      let!(:evidence_submission_task) do
        create(:evidence_submission_window_task, :in_progress, appeal: appeal, assigned_to: Bva.singleton)
      end

      it "has an evidentiary_period alert" do
        expect(subject.count).to eq(1)
        expect(subject[0][:type]).to eq("evidentiary_period")
        expect(subject[0][:details][:due_date]).to eq((receipt_date + 90.days).to_date)
      end
    end

    context "has a scheduled hearing" do
      let!(:appeal_root_task) { create(:root_task, :in_progress, appeal: appeal) }
      let!(:hearing_task) { create(:hearing_task, parent: appeal_root_task, appeal: appeal) }
      let(:hearing_scheduled_for) { Time.zone.today + 15.days }
      let!(:hearing_day) do
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               regional_office: "RO18",
               scheduled_for: hearing_scheduled_for)
      end

      let!(:hearing) do
        create(
          :hearing,
          appeal: appeal,
          disposition: nil,
          evidence_window_waived: nil,
          hearing_day: hearing_day
        )
      end
      let!(:hearing_task_association) do
        create(
          :hearing_task_association,
          hearing: hearing,
          hearing_task: hearing_task
        )
      end
      let!(:schedule_hearing_task) do
        create(
          :schedule_hearing_task,
          :completed,
          parent: hearing_task,
          appeal: appeal
        )
      end
      let!(:disposition_task) do
        create(
          :assign_hearing_disposition_task,
          :in_progress,
          parent: hearing_task,
          appeal: appeal
        )
      end

      it "has a scheduled hearing alert" do
        expect(subject.count).to eq(1)
        expect(subject[0][:type]).to eq("scheduled_hearing")
        expect(subject[0][:details][:date]).to eq(hearing_scheduled_for.to_date)
        expect(subject[0][:details][:type]).to eq("video")
      end
    end
  end

  describe "#stuck?" do
    context "Appeal has BvaDispatchTask completed but still on hold" do
      let(:appeal) do
        appeal = create(:appeal, :with_post_intake_tasks)
        create(:bva_dispatch_task, :completed, appeal: appeal)
        appeal
      end

      it "returns true" do
        expect(appeal.stuck?).to eq(true)
      end
    end
  end
end
