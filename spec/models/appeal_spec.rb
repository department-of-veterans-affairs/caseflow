describe Appeal do
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

  context "ready appeals" do
    let!(:direct_review_appeal) { create(:appeal, docket_type: "direct_review") }
    let!(:hearing_appeal) { create(:appeal, docket_type: "hearing") }
    let!(:evidence_submission_appeal) { create(:appeal, docket_type: "evidence_submission") }

    before do
      FeatureToggle.enable!(:ama_auto_case_distribution)
    end
    after do
      FeatureToggle.disable!(:ama_auto_case_distribution)
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

  context "#create_remand_supplemental_claims!" do
    subject { appeal.create_remand_supplemental_claims! }

    let!(:remanded_decision_issue) do
      create(
        :decision_issue,
        decision_review: appeal,
        disposition: "remanded",
        benefit_type: "compensation"
      )
    end

    let!(:remanded_decision_issue_processed_in_caseflow) do
      create(:decision_issue, decision_review: appeal, disposition: "remanded", benefit_type: "nca")
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

  context "#new_documents_from_caseflow" do
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

    subject { appeal.new_documents_from_caseflow(user) }

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
             participant_id: veteran.participant_id)
    end

    let!(:future_decision_issue) do
      create(:decision_issue,
             decision_review: another_review,
             profile_date: receipt_date + 1.day,
             benefit_type: another_review.benefit_type,
             decision_text: "something was decided in the future",
             description: "future issue",
             participant_id: veteran.participant_id)
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
      let(:decision_issues) { [create(:decision_issue)] }

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
    let(:appeal) do
      create(:appeal)
    end

    it "creates root and vso tasks" do
      expect(RootTask).to receive(:create_root_and_sub_tasks!).once

      appeal.create_tasks_on_intake_success!
    end

    context "request issue has non-comp business line" do
      let(:appeal) do
        create(:appeal, request_issues: [create(:request_issue, benefit_type: :fiduciary)])
      end

      it "creates root task and veteran record request task" do
        expect(VeteranRecordRequest).to receive(:create!).once

        appeal.create_tasks_on_intake_success!
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
      it "returns nil" do
        expect(appeal.location_code).to eq(nil)
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

      before do
        organization_root_task = create(:root_task, appeal: appeal_organization)
        create(:generic_task, assigned_to: organization, appeal: appeal_organization, parent: organization_root_task)

        user_root_task = create(:root_task, appeal: appeal_user)
        create(:generic_task, assigned_to: user, appeal: appeal_user, parent: user_root_task)
      end

      it "if the most recent assignee is an organization it returns the organization name" do
        expect(appeal_organization.location_code).to eq(organization.name)
      end

      it "if the most recent assignee is not an organization it returns the id" do
        expect(appeal_user.location_code).to eq(user.css_id)
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

  context "#status_hash" do
    let(:judge) { create(:user) }
    let!(:hearings_user) { create(:hearings_coordinator) }
    let(:appeal) { create(:appeal) }
    let(:root_task_status) { "in_progress" }
    let!(:appeal_root_task) { create(:root_task, appeal: appeal, status: root_task_status) }

    context "appeal not assigned" do
      it "is on docket" do
        status = appeal.status_hash
        expect(status[:type]).to eq(:on_docket)
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
      end
    end

    context "have a decision with no remands or effection" do
      let(:judge_review_task_status) { "completed" }
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task,
               assigned_to: judge, appeal: appeal, status: judge_review_task_status)
      end
      let(:root_task_status) { "completed" }
      let!(:not_remanded_decision_issue) { create(:decision_issue, decision_review: appeal) }

      it "has a decision" do
        status = appeal.status_hash
        expect(status[:type]).to eq(:bva_decision)
      end
    end

    context "has an effectuation" do
      let(:root_task_status) { "completed" }
      let(:judge_review_task_status) { "completed" }
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task,
               assigned_to: judge, appeal: appeal, status: judge_review_task_status)
      end
      let!(:not_remanded_decision_issue) { create(:decision_issue, decision_review: appeal) }
      let(:decision_document) { create(:decision_document, appeal: appeal) }
      let(:ep_status) { "CLR" }
      let!(:effectuation_ep) { create(:end_product_establishment, source: decision_document, synced_status: ep_status) }

      it "effectuation had an ep" do
        status = appeal.status_hash
        expect(status[:type]).to eq(:bva_decision_effectuation)
      end
    end

    context "has a remand" do
      let(:root_task_status) { "completed" }
      let(:judge_review_task_status) { "completed" }
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task,
               assigned_to: judge, appeal: appeal, status: judge_review_task_status)
      end
      let!(:not_remanded_decision_issue) { create(:decision_issue, decision_review: appeal) }
      let!(:remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal, disposition: "remanded", benefit_type: "nca")
      end

      it "it only has a remand that was processed in caseflow" do
        status = appeal.status_hash
        expect(status[:type]).to eq(:ama_remand)
      end
    end

    context "has more than one remanded decision" do
      let(:root_task_status) { "completed" }
      let(:judge_review_task_status) { "completed" }
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task,
               assigned_to: judge, appeal: appeal, status: judge_review_task_status)
      end
      let!(:not_remanded_decision_issue) { create(:decision_issue, decision_review: appeal) }
      let!(:remanded_issue) do
        create(:decision_issue,
               decision_review: appeal, disposition: "remanded", benefit_type: "nca")
      end
      let!(:remanded_issue_with_ep) do
        create(:decision_issue,
               decision_review: appeal, disposition: "remanded", benefit_type: "compensation")
      end
      let(:remanded_sc) { create(:supplemental_claim, decision_review_remanded: appeal) }
      let!(:remanded_ep) { create(:end_product_establishment, source: remanded_sc, synced_status: "CLR") }

      it "has a remand processed in vbms" do
        status = appeal.status_hash
        expect(status[:type]).to eq(:post_bva_dta_decision)
      end
    end
  end
end
