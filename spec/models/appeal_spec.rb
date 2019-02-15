require "rails_helper"
require "support/intake_helpers"

describe Appeal do
  include IntakeHelpers

  let!(:appeal) { create(:appeal) }

  context "priority and non-priority appeals" do
    let!(:aod_age_appeal) { create(:appeal, :advanced_on_docket_due_to_age) }
    let!(:aod_motion_appeal) { create(:appeal, :advanced_on_docket_due_to_motion) }
    let!(:denied_aod_motion_appeal) { create(:appeal, :denied_advance_on_docket) }
    let!(:inapplicable_aod_motion_appeal) { create(:appeal, :inapplicable_aod_motion) }

    context "#all_priority" do
      subject { Appeal.all_priority }
      it "returns aod appeals due to age and motion" do
        expect(subject.include?(aod_age_appeal)).to eq(true)
        expect(subject.include?(aod_motion_appeal)).to eq(true)
        expect(subject.include?(appeal)).to eq(false)
        expect(subject.include?(denied_aod_motion_appeal)).to eq(false)
        expect(subject.include?(inapplicable_aod_motion_appeal)).to eq(false)
      end
    end

    context "#all_nonpriority" do
      subject { Appeal.all_nonpriority }
      it "returns non aod appeals" do
        expect(subject.include?(appeal)).to eq(true)
        expect(subject.include?(aod_motion_appeal)).to eq(false)
        expect(subject.include?(denied_aod_motion_appeal)).to eq(true)
        expect(subject.include?(inapplicable_aod_motion_appeal)).to eq(true)
      end
    end
  end

  context "active appeals" do
    let!(:active_appeal) { create(:appeal, :with_tasks) }
    let!(:inactive_appeal) { create(:appeal, :outcoded) }

    subject { Appeal.active }
    it "returns only active appeals" do
      expect(subject.include?(active_appeal)).to eq(true)
      expect(subject.include?(inactive_appeal)).to eq(false)
    end
  end

  context "ready appeals" do
    let!(:direct_review_appeal) { create(:appeal, docket_type: "direct_review") }
    let!(:hearing_appeal) { create(:appeal, docket_type: "hearing") }
    let!(:evidence_submission_appeal) { create(:appeal, docket_type: "evidence_submission") }

    before do
      FeatureToggle.enable!(:ama_acd_tasks)
    end
    after do
      FeatureToggle.disable!(:ama_acd_tasks)
    end
    subject { Appeal.ready_for_distribution }

    it "returns appeals" do
      [direct_review_appeal, evidence_submission_appeal, hearing_appeal].each do |appeal|
        RootTask.create_root_and_sub_tasks!(appeal)
      end

      expect(subject.include?(direct_review_appeal)).to eq(true)
      expect(subject.include?(evidence_submission_appeal)).to eq(false)
      # TODO: support hearing appeals
      # expect(subject.include?(hearing_appeal)).to eq(false)
    end
  end

  context "ready appeals sorted by date" do
    let!(:first_appeal) { create(:appeal, :with_tasks) }
    let!(:second_appeal) { create(:appeal, :with_tasks) }

    subject { Appeal.ordered_by_distribution_ready_date }

    it "returns appeals ordered by when they became ready for distribution" do
      expect(subject.find_index(first_appeal) < subject.find_index(second_appeal)).to eq(true)
    end
  end

  context "#create_remand_supplemental_claims!" do
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

    let!(:prior_sc_with_payee_code) { setup_prior_claim_with_payee_code(appeal, veteran) }

    it "creates supplemental claim, request issues, and starts processing" do
      subject

      remanded_supplemental_claims = SupplementalClaim.where(decision_review_remanded: appeal)
        .where.not(id: prior_sc_with_payee_code.id)

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

  context "#new_documents_for_user" do
    before do
      documents.each { |document| document.update(file_number: appeal.veteran_file_number) }
    end

    let(:user) { create(:user) }

    let!(:documents) do
      [
        Generators::Document.create(upload_date: 5.days.ago),
        Generators::Document.create(upload_date: 5.days.ago)
      ]
    end

    let!(:appeal) { create(:appeal) }

    context "when no alternative date is provided" do
      subject { appeal.new_documents_for_user(user: user) }

      context "when appeal has no appeal view" do
        it "should return all documents" do
          expect(subject).to match_array(documents)
        end
      end

      context "when appeal has an appeal view newer than documents" do
        let!(:appeal_view) { AppealView.create(appeal: appeal, user: user, last_viewed_at: Time.zone.now) }

        it "should return no documents" do
          expect(subject).to eq([])
        end

        context "when one document is missing a received at date" do
          it "should return no documents" do
            documents[0].update(upload_date: nil)
            expect(subject).to eq([])
          end
        end

        context "when one document is newer than the appeal view date" do
          it "should return the newer document" do
            documents[0].update(upload_date: -2.days.ago)
            expect(subject).to eq([documents[0]])
          end
        end
      end
    end

    context "when providing an on_hold date" do
      subject { appeal.new_documents_for_user(user: user, placed_on_hold_at: 4.days.ago.to_i.to_s) }

      context "When one document's upload date is after on hold date" do
        it "should return only the newest document" do
          documents[0].update(upload_date: 3.days.ago)
          expect(subject).to eq([documents[0]])
        end
      end

      context "when appeal has an appeal view newer than the on hold date" do
        let!(:appeal_view) { AppealView.create(appeal: appeal, user: user, last_viewed_at: 2.days.ago) }

        it "should return no documents" do
          expect(subject).to eq([])
        end

        context "when one document's upload date is after the last viewed date" do
          it "should return the document uploaded after the view, but not the one after the hold date" do
            documents[1].update(upload_date: 1.day.ago)
            expect(subject).to eq([documents[1]])
          end
        end
      end
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
             profile_date: receipt_date - 1.day,
             benefit_type: another_review.benefit_type,
             decision_text: "something decided in the past",
             description: "past issue",
             participant_id: veteran.participant_id,
             end_product_last_action_date: receipt_date - 1.day)
    end

    let!(:future_decision_issue) do
      create(:decision_issue,
             decision_review: another_review,
             profile_date: receipt_date + 1.day,
             promulgation_date: receipt_date + 1.day,
             benefit_type: another_review.benefit_type,
             decision_text: "something was decided in the future",
             description: "future issue",
             participant_id: veteran.participant_id,
             end_product_last_action_date: receipt_date - 1.day)
    end

    it "does not return Decision Issues in the future" do
      expect(subject.count).to eq(1)
      expect(subject.first.decision_issue_id).to eq(past_decision_issue.id)
    end
  end

  context "async logic scopes" do
    let!(:appeal_requiring_processing) do
      create(:appeal).tap(&:submit_for_processing!)
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
        expect(Appeal.unexpired).to eq([appeal_requiring_processing])
      end
    end

    context ".processable" do
      it "matches appeals eligible for processing" do
        expect(Appeal.processable).to match_array(
          [appeal_requiring_processing, appeal_attempts_ended]
        )
      end
    end

    context ".attemptable" do
      it "matches appeals that could be attempted" do
        expect(Appeal.attemptable).not_to include(appeal_recently_attempted)
      end
    end

    context ".requires_processing" do
      it "matches appeals that must still be processed" do
        expect(Appeal.requires_processing).to eq([appeal_requiring_processing])
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

  context "#advanced_on_docket" do
    context "when a claimant is advanced_on_docket" do
      let(:appeal) do
        create(:appeal, claimants: [create(:claimant, :advanced_on_docket_due_to_age)])
      end

      it "returns true" do
        expect(appeal.advanced_on_docket).to eq(true)
      end
    end

    context "when no claimant is advanced_on_docket" do
      let(:appeal) do
        create(:appeal)
      end

      it "returns false" do
        expect(appeal.advanced_on_docket).to eq(false)
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

    context "#vsos" do
      it "returns all vsos this appeal has that exist in our DB" do
        expect(appeal.vsos.count).to eq(1)
        expect(appeal.vsos.first.name).to eq("Paralyzed Veterans Of America")
      end
    end
  end

  context ".create_tasks_on_intake_success!" do
    let!(:appeal) { create(:appeal) }

    subject { appeal.create_tasks_on_intake_success! }

    it "creates root and vso tasks" do
      expect(RootTask).to receive(:create_root_and_sub_tasks!).once

      subject
    end

    context "request issue has non-comp business line" do
      let!(:appeal) { create(:appeal, request_issues: [create(:request_issue, benefit_type: :fiduciary)]) }

      it "creates root task and veteran record request task" do
        expect(VeteranRecordRequest).to receive(:create!).once

        subject
      end
    end

    context "creating translation tasks" do
      let(:bgs_veteran_state) { nil }
      let(:bgs_veteran_record) { { state: bgs_veteran_state } }
      let(:validated_veteran_state) { nil }
      let(:mock_va_dot_gov_address) { { state_code: validated_veteran_state } }
      let(:veteran) { FactoryBot.create(:veteran, bgs_veteran_record: bgs_veteran_record) }
      let(:appeal) { FactoryBot.create(:appeal, veteran: veteran) }

      context "VADotGovService is responsive" do
        before do
          allow(VADotGovService).to receive(:validate_address).and_return(mock_va_dot_gov_address)
        end

        context "the service returns a state code" do
          context "the state code is PR or PI" do
            let(:validated_veteran_state) { "PR" }

            it "creates a translation task" do
              expect(TranslationTask).to receive(:create_from_root_task).once.with(kind_of(RootTask))

              subject
            end

            context "the bgs veteran record has a different state code" do
              let(:validated_veteran_state) { "PI" }
              let(:bgs_veteran_state) { "NV" }

              it "prefers the service state code and creates a translation task" do
                expect(TranslationTask).to receive(:create_from_root_task).once.with(kind_of(RootTask))

                subject
              end
            end
          end

          context "the state code is not PR or PI" do
            let(:validated_veteran_state) { "NV" }

            it "doesn't create a translation task" do
              expect(TranslationTask).to_not receive(:create_from_root_task)

              subject
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
            expect(TranslationTask).to_not receive(:create_from_root_task)

            subject
          end
        end

        context "the bgs veteran record has a state code" do
          context "the state code is PR or PI" do
            let(:bgs_veteran_state) { "PI" }

            it "creates a translation task" do
              expect(TranslationTask).to receive(:create_from_root_task).once.with(kind_of(RootTask))

              subject
            end
          end

          context "the state code is not PR or PI" do
            let(:bgs_veteran_state) { "NV" }

            it "doesn't create a translation task" do
              expect(TranslationTask).to_not receive(:create_from_root_task)

              subject
            end
          end
        end
      end
    end
  end

  context "#location_code" do
    context "if the RootTask status is completed" do
      let(:appeal) { create(:appeal) }

      before do
        create(:root_task, appeal: appeal, status: :completed)
      end

      it "returns Post-decision" do
        expect(appeal.location_code).to eq(COPY::CASE_LIST_TABLE_POST_DECISION_LABEL)
      end
    end

    context "if there are no active tasks" do
      let(:appeal) { create(:appeal) }
      it "returns 'other close'" do
        expect(appeal.location_code).to eq(:other_close.to_s.titleize)
      end
    end

    context "if the only active case is a RootTask" do
      let(:appeal) { create(:appeal) }

      before do
        create(:root_task, appeal: appeal, status: :in_progress)
      end

      it "returns Case storage" do
        expect(appeal.location_code).to eq(COPY::CASE_LIST_TABLE_CASE_STORAGE_LABEL)
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
        create(:generic_task, status: :on_hold, appeal: appeal_on_hold, parent: on_hold_root, updated_at: today + 1)
      end

      it "if the most recent assignee is an organization it returns the organization name" do
        expect(appeal_organization.location_code).to eq(organization.name)
      end

      it "if the most recent assignee is not an organization it returns the id" do
        expect(appeal_user.location_code).to eq(user.css_id)
      end

      it "if the task is on hold but there isn't an assignee it returns something" do
        expect(appeal_on_hold.location_code).not_to eq(nil)
      end
    end
  end

  context "is taskable" do
    context "#assigned_attorney" do
      let(:attorney) { create(:user) }
      let(:appeal) { create(:appeal) }
      let!(:task) { create(:ama_attorney_task, assigned_to: attorney, appeal: appeal) }

      subject { appeal.assigned_attorney }

      it { is_expected.to eq attorney }
    end

    context "#assigned_judge" do
      let(:judge) { create(:user) }
      let(:appeal) { create(:appeal) }
      let!(:task) { create(:ama_judge_task, assigned_to: judge, appeal: appeal) }

      subject { appeal.assigned_judge }

      it { is_expected.to eq judge }
    end
  end

  context ".active?" do
    subject { appeal.active? }

    context "when there are no tasks for an appeal" do
      let(:appeal) { FactoryBot.create(:appeal) }

      it "should indicate the appeal is not active" do
        expect(subject).to eq(false)
      end
    end

    context "when there are only completed tasks for an appeal" do
      let(:appeal) { FactoryBot.create(:appeal) }

      before do
        FactoryBot.create_list(:task, 6, :completed, appeal: appeal)
      end

      it "should indicate the appeal is not active" do
        expect(subject).to eq(false)
      end
    end

    context "when there are incomplete tasks for an appeal" do
      let(:appeal) { FactoryBot.create(:appeal) }

      before do
        FactoryBot.create_list(:task, 3, :in_progress, appeal: appeal)
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
        FactoryBot.create_list(:task, 3, :in_progress, type: RootTask.name, appeal: appeal)
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

  context "#nonpriority_decisions_per_year" do
    let!(:newer_decisions) do
      (0...18).map do |num|
        doc = create(:decision_document, decision_date: (num * 20).days.ago)
        doc.appeal.update(docket_type: "direct_review")
        doc.appeal
      end
    end
    let!(:older_decisions) do
      (0...2).map do |num|
        doc = create(:decision_document, decision_date: (366 + (num * 20)).days.ago)
        doc.appeal.update(docket_type: "direct_review")
        doc.appeal
      end
    end

    context "non-priority decision list" do
      subject { Appeal.nonpriority_decisions_per_year }

      it "returns decisions from the last year" do
        expect(subject).to eq(18)
      end
    end
  end

  context "#set_target_decision_date!" do
    let(:direct_review_appeal) { create(:appeal, docket_type: "direct_review") }
    let(:evidence_submission_appeal) { create(:appeal, docket_type: "evidence_submission") }

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

  context "#status_hash" do
    let(:judge) { create(:user) }
    let!(:hearings_user) { create(:hearings_coordinator) }
    let!(:receipt_date) { DecisionReview.ama_activation_date + 1 }
    let(:appeal) { create(:appeal, receipt_date: receipt_date) }
    let(:root_task_status) { "in_progress" }
    let!(:appeal_root_task) { create(:root_task, appeal: appeal, status: root_task_status) }

    context "appeal not assigned" do
      it "is on docket" do
        status = appeal.status_hash
        expect(status[:type]).to eq(:on_docket)
        expect(status[:details]).to be_empty
      end
    end

    context "hearing to be scheduled" do
      let(:schedule_hearing_status) { "in_progress" }
      let!(:schedule_hearing_task) do
        ScheduleHearingTask.create!(appeal: appeal, assigned_to: hearings_user, status: schedule_hearing_status)
      end

      it "is waiting for hearing to be scheduled" do
        status = appeal.status_hash
        expect(status[:type]).to eq(:pending_hearing_scheduling)
        expect(status[:details][:type]).to eq("video")
      end
    end

    context "in an evidence submission window" do
      let(:schedule_hearing_status) { "completed" }
      let!(:schedule_hearing_task) do
        ScheduleHearingTask.create!(appeal: appeal, assigned_to: hearings_user, status: schedule_hearing_status)
      end
      let(:evidence_hold_task_status) { "in_progress" }
      let!(:evidence_submission_task) do
        EvidenceSubmissionWindowTask.create!(appeal: appeal,
                                             status: evidence_hold_task_status, assigned_to: Bva.singleton)
      end
      let(:judge_review_task_status) { "in_progress" }
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task,
               assigned_to: judge, appeal: appeal, status: judge_review_task_status)
      end

      it "is in evidentiary period " do
        status = appeal.status_hash
        expect(status[:type]).to eq(:evidentiary_period)
        expect(status[:details]).to be_empty
      end
    end

    context "assigned to judge" do
      let(:schedule_hearing_status) { "completed" }
      let!(:schedule_hearing_task) do
        ScheduleHearingTask.create!(appeal: appeal, assigned_to: hearings_user, status: schedule_hearing_status)
      end
      let(:evidence_hold_task_status) { "completed" }
      let!(:evidence_submission_task) do
        EvidenceSubmissionWindowTask.create!(appeal: appeal,
                                             status: evidence_hold_task_status, assigned_to: Bva.singleton)
      end
      let(:judge_review_task_status) { "in_progress" }
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task,
               assigned_to: judge, appeal: appeal, status: judge_review_task_status)
      end

      it "waiting for a decision" do
        status = appeal.status_hash
        expect(status[:type]).to eq(:decision_in_progress)
        expect(status[:details]).to be_empty
      end
    end

    context "have a decision with no remands or effectuation" do
      let(:judge_review_task_status) { "completed" }
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task,
               assigned_to: judge, appeal: appeal, status: judge_review_task_status)
      end
      let(:root_task_status) { "completed" }
      let!(:not_remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal, disposition: "allowed")
      end

      it "has a decision" do
        status = appeal.status_hash
        expect(status[:type]).to eq(:bva_decision)
        expect(status[:details][:issues].first[:description]).to eq("Dental or oral condition")
        expect(status[:details][:issues].first[:disposition]).to eq("allowed")
      end
    end

    context "has an effectuation" do
      let(:root_task_status) { "completed" }
      let(:judge_review_task_status) { "completed" }
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task,
               assigned_to: judge, appeal: appeal, status: judge_review_task_status)
      end
      let!(:not_remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal, caseflow_decision_date: receipt_date + 60.days)
      end
      let(:decision_document) { create(:decision_document, appeal: appeal) }
      let(:ep_status) { "CLR" }
      let!(:effectuation_ep) do
        create(:end_product_establishment,
               source: decision_document, synced_status: ep_status, last_synced_at: receipt_date + 100.days)
      end

      it "effectuation had an ep" do
        status = appeal.status_hash
        expect(status[:type]).to eq(:bva_decision_effectuation)
        expect(status[:details][:bvaDecisionDate].to_date).to eq((receipt_date + 60.days).to_date)
        expect(status[:details][:aojDecisionDate].to_date).to eq((receipt_date + 100.days).to_date)
      end
    end

    context "has an active remand" do
      let(:root_task_status) { "completed" }
      let(:judge_review_task_status) { "completed" }
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task,
               assigned_to: judge, appeal: appeal, status: judge_review_task_status)
      end
      let!(:not_remanded_decision_issue) { create(:decision_issue, decision_review: appeal) }
      let!(:remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal,
               disposition: "remanded",
               benefit_type: "nca",
               diagnostic_code: nil,
               caseflow_decision_date: 1.day.ago)
      end

      it "it has status ama_remand" do
        appeal.create_remand_supplemental_claims!
        appeal.remand_supplemental_claims.each(&:reload)
        status = appeal.status_hash
        expect(status[:type]).to eq(:ama_remand)
        expect(status[:details][:issues].count).to eq(2)
      end
    end

    context "has multiple remands" do
      let(:root_task_status) { "completed" }
      let(:judge_review_task_status) { "completed" }
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task,
               assigned_to: judge, appeal: appeal, status: judge_review_task_status)
      end
      let!(:not_remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal, caseflow_decision_date: receipt_date + 60.days)
      end
      let!(:remanded_issue) do
        create(:decision_issue,
               decision_review: appeal,
               disposition: "remanded",
               benefit_type: "nca",
               caseflow_decision_date: receipt_date + 60.days)
      end
      let!(:remanded_issue_with_ep) do
        create(:decision_issue,
               decision_review: appeal,
               disposition: "remanded",
               benefit_type: "compensation",
               diagnostic_code: "9912",
               caseflow_decision_date: receipt_date + 60.days)
      end
      let!(:remanded_sc) do
        create(
          :supplemental_claim,
          veteran_file_number: appeal.veteran_file_number,
          decision_review_remanded: appeal,
          benefit_type: remanded_issue.benefit_type
        )
      end
      let!(:remanded_sc_decision) do
        create(:decision_issue,
               decision_review: remanded_sc,
               disposition: "granted",
               diagnostic_code: "9915",
               caseflow_decision_date: receipt_date + 101.days)
      end
      let!(:remanded_sc_with_ep) do
        create(
          :supplemental_claim,
          veteran_file_number: appeal.veteran_file_number,
          decision_review_remanded: appeal,
          benefit_type: remanded_issue_with_ep.benefit_type
        )
      end
      let!(:remanded_ep) do
        create(:end_product_establishment,
               :cleared, source: remanded_sc_with_ep, last_synced_at: receipt_date + 100.days)
      end
      let!(:remanded_sc_with_ep_decision) do
        create(:decision_issue,
               decision_review: remanded_sc_with_ep,
               disposition: "denied",
               diagnostic_code: "9912",
               end_product_last_action_date: receipt_date + 100.days)
      end

      context "they are all complete" do
        let!(:remanded_sc_task) { create(:task, :completed, appeal: remanded_sc) }
        it "has post_bva_dta_decision status,shows the latest decision date, and remand dedision issues" do
          status = appeal.status_hash
          expect(status[:type]).to eq(:post_bva_dta_decision)
          expect(status[:details][:issues]).to include(
            { description: "Partial loss of upper jaw", disposition: "granted" },
            description: "Partial loss of hard palate", disposition: "denied"
          )
          expect(status[:details][:bvaDecisionDate]).to eq((receipt_date + 60.days).to_date)
          expect(status[:details][:aojDecisionDate]).to eq((receipt_date + 101.days).to_date)
        end
      end

      context "they are not all complete" do
        let!(:remanded_sc_task) { create(:task, :in_progress, appeal: remanded_sc) }
        it "has ama_remand status, no decision dates, and shows appeals decision issues" do
          status = appeal.status_hash
          expect(status[:type]).to eq(:ama_remand)
          expect(status[:details][:issues]).to include(
            { description: "Dental or oral condition", disposition: "allowed" },
            { description: "Partial loss of hard palate", disposition: "remanded" },
            description: "Partial loss of hard palate", disposition: "remanded"
          )
          expect(status[:details][:bvaDecisionDate]).to be_nil
          expect(status[:details][:aojDecisionDate]).to be_nil
        end
      end
    end
  end

  context "#events" do
    let(:receipt_date) { DecisionReview.ama_activation_date + 1 }
    let!(:appeal) { create(:appeal, receipt_date: receipt_date) }
    let!(:decision_date) { receipt_date + 130.days }
    let!(:decision_document) { create(:decision_document, appeal: appeal, decision_date: decision_date) }
    let(:judge) { create(:user) }
    let(:judge_task_created_date) { receipt_date + 10 }
    let!(:judge_review_task) do
      create(:ama_judge_decision_review_task,
             assigned_to: judge, appeal: appeal, created_at: judge_task_created_date, status: "completed")
    end
    let!(:judge_quality_review_task) do
      create(:ama_judge_quality_review_task,
             assigned_to: judge, appeal: appeal, created_at: judge_task_created_date + 2.days, status: "completed")
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

    let(:promulgation_date1) { receipt_date - 50.days }
    let(:request_issue1) { create(:request_issue) }
    let(:promulgation_date2) { receipt_date - 60.days }
    let(:request_issue2) { create(:request_issue) }
    let(:promulgation_date3) { receipt_date - 100.days }
    let(:removed_request_issue) { create(:request_issue, :removed, closed_at: receipt_date) }

    let(:docket_type) { "direct_review" }
    let!(:appeal) do
      create(:appeal,
             receipt_date: receipt_date,
             request_issues: [request_issue1, request_issue2, removed_request_issue],
             docket_type: docket_type)
    end

    let!(:root_task) { create(:root_task, :in_progress, appeal: appeal) }

    context "all request issues have a decision or promulgation date" do
      before do
        Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))

        allow(request_issue1).to receive(:decision_or_promulgation_date).and_return(promulgation_date1)
        allow(request_issue2).to receive(:decision_or_promulgation_date).and_return(promulgation_date2)
        allow(removed_request_issue).to receive(:decision_or_promulgation_date).and_return(promulgation_date3)
      end

      it "is direct review, in Oct month, has docket switch deadline and is eligible to switch" do
        docket = appeal.docket_hash

        expect(docket).not_to be_nil
        expect(docket[:type]).to eq("directReview")
        expect(docket[:month]).to eq(october_docket_date.to_date)
        expect(docket[:switchDueDate]).to eq((promulgation_date2 + 365.days))
        expect(docket[:eligibleToSwitch]).to eq(true)
      end
    end

    context "cannot get decision or promulgation date for an open request issue" do
      before do
        Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))

        allow(request_issue2).to receive(:decision_or_promulgation_date).and_return(promulgation_date2)
      end

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

  context "#issues_hash" do
    let(:receipt_date) { DecisionReview.ama_activation_date + 1 }

    let(:request_issue1) do
      create(:request_issue,
             benefit_type: "compensation", contested_rating_issue_diagnostic_code: "5002")
    end
    let(:request_issue2) do
      create(:request_issue,
             benefit_type: "pension", contested_rating_issue_diagnostic_code: nil)
    end

    let!(:appeal) do
      create(:appeal, receipt_date: receipt_date,
                      request_issues: [request_issue1, request_issue2])
    end

    let!(:root_task) { create(:root_task, :in_progress, appeal: appeal) }

    context "appeal pending a decision" do
      it "is status of the request issues" do
        issue_statuses = appeal.issues_hash

        expect(issue_statuses.empty?).to eq(false)

        issue = issue_statuses.find { |i| i[:diagnosticCode] == "5002" }
        expect(issue).to_not be_nil
        expect(issue[:active]).to eq(true)
        expect(issue[:last_action]).to be_nil
        expect(issue[:date]).to be_nil
        expect(issue[:description]).to eq("Rheumatoid arthritis")

        issue2 = issue_statuses.find { |i| i[:diagnosticCode].nil? }
        expect(issue2).to_not be_nil
        expect(issue2[:active]).to eq(true)
        expect(issue2[:last_action]).to be_nil
        expect(issue2[:date]).to be_nil
        expect(issue2[:description]).to eq("Pension issue")
      end
    end

    context "have decisions, one is remanded" do
      let!(:decision_date) { receipt_date + 130.days }
      let!(:decision_document) { create(:decision_document, appeal: appeal, decision_date: decision_date) }

      let!(:not_remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal, benefit_type: "pension", disposition: "allowed",
               diagnostic_code: nil,
               caseflow_decision_date: decision_date)
      end
      let!(:remanded_issue_with_ep) do
        create(:decision_issue,
               decision_review: appeal, disposition: "remanded", benefit_type: "compensation",
               diagnostic_code: "5002", caseflow_decision_date: decision_date)
      end
      let(:remanded_sc) { create(:supplemental_claim, decision_review_remanded: appeal) }
      let!(:remanded_ep) { create(:end_product_establishment, source: remanded_sc, synced_status: "PEND") }

      it "remanded decision as active, other decision as inactive" do
        issue_statuses = appeal.issues_hash

        expect(issue_statuses.empty?).to eq(false)

        issue = issue_statuses.find { |i| i[:diagnosticCode] == "5002" }
        expect(issue).to_not be_nil
        expect(issue[:active]).to eq(true)
        expect(issue[:last_action]).to eq("remand")
        expect(issue[:date].to_date).to eq(decision_date.to_date)
        expect(issue[:description]).to eq("Rheumatoid arthritis")

        issue2 = issue_statuses.find { |i| i[:diagnosticCode].nil? }
        expect(issue2).to_not be_nil
        expect(issue2[:active]).to eq(false)
        expect(issue2[:last_action]).to eq("allowed")
        expect(issue2[:date].to_date).to eq(decision_date.to_date)
        expect(issue2[:description]).to eq("Pension issue")
      end
    end

    context "remanded sc has decision" do
      let!(:decision_date) { receipt_date + 130.days }
      let!(:decision_document) { create(:decision_document, appeal: appeal, decision_date: decision_date) }

      let!(:not_remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal, benefit_type: "pension", disposition: "allowed",
               diagnostic_code: nil,
               caseflow_decision_date: decision_date)
      end
      let!(:remanded_issue_with_ep) do
        create(:decision_issue,
               decision_review: appeal, disposition: "remanded", benefit_type: "compensation",
               diagnostic_code: "5002", caseflow_decision_date: decision_date)
      end
      let(:remanded_sc) { create(:supplemental_claim, decision_review_remanded: appeal) }
      let!(:remanded_ep) { create(:end_product_establishment, source: remanded_sc, synced_status: "CLR") }
      let(:remand_sc_decision_date) { decision_date + 30.days }

      let!(:remanded_sc_decision) do
        create(:decision_issue,
               decision_review: remanded_sc, disposition: "denied", benefit_type: "compensation",
               diagnostic_code: "5002", end_product_last_action_date: remand_sc_decision_date)
      end

      it "has the remand sc decision and other decision" do
        issue_statuses = appeal.issues_hash

        expect(issue_statuses.empty?).to eq(false)
        issue = issue_statuses.find { |i| i[:diagnosticCode] == "5002" }
        expect(issue).to_not be_nil
        expect(issue[:active]).to eq(false)
        expect(issue[:last_action]).to eq("denied")
        expect(issue[:date].to_date).to eq(remand_sc_decision_date.to_date)
        expect(issue[:description]).to eq("Rheumatoid arthritis")

        issue2 = issue_statuses.find { |i| i[:diagnosticCode].nil? }
        expect(issue2).to_not be_nil
        expect(issue2[:active]).to eq(false)
        expect(issue2[:last_action]).to eq("allowed")
        expect(issue2[:date].to_date).to eq(decision_date.to_date)
        expect(issue2[:description]).to eq("Pension issue")
      end
    end
  end
end
