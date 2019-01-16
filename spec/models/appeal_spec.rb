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
        benefit_type: "compensation",
        end_product_last_action_date: 10.days.ago.to_date
      )
    end

    let!(:remanded_decision_issue_processed_in_caseflow) do
      create(
        :decision_issue, decision_review: appeal, disposition: "remanded", benefit_type: "nca", profile_date: 5.days.ago
      )
    end

    let!(:not_remanded_decision_issue) { create(:decision_issue, decision_review: appeal) }

    it "creates supplemental claim, request issues, and starts processing" do
      subject

      remanded_supplemental_claims = SupplementalClaim.where(decision_review_remanded: appeal)

      expect(remanded_supplemental_claims.count).to eq(2)

      vbms_remand = remanded_supplemental_claims.find_by(benefit_type: "compensation")
      expect(vbms_remand).to have_attributes(
        receipt_date: remanded_decision_issue.approx_decision_date
      )
      expect(vbms_remand.request_issues.count).to eq(1)
      expect(vbms_remand.request_issues.first).to have_attributes(
        contested_decision_issue: remanded_decision_issue
      )
      expect(vbms_remand.end_product_establishments.first).to be_committed
      expect(vbms_remand.tasks).to be_empty

      caseflow_remand = remanded_supplemental_claims.find_by(benefit_type: "nca")
      expect(caseflow_remand).to have_attributes(
        receipt_date: remanded_decision_issue_processed_in_caseflow.approx_decision_date
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
        establishment_submitted_at: (Appeal::REQUIRES_PROCESSING_WINDOW_DAYS + 5).days.ago,
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

  context ".tasks_for_timeline" do
    context "when there are completed organization tasks with completed child tasks assigned to people" do
      let(:judge) { create(:user) }
      let(:appeal) { create(:appeal) }
      let!(:task) { create(:ama_judge_task, assigned_to: judge, appeal: appeal) }
      let!(:task2) do
        create(:qr_task, appeal: appeal, status: Constants.TASK_STATUSES.completed, assigned_to_type: "Organization")
      end
      let!(:task3) do
        create(:qr_task, assigned_to: judge, appeal: appeal, status: Constants.TASK_STATUSES.completed,
                         parent_id: task2.id)
      end

      subject { appeal.tasks_for_timeline.first }
      it { is_expected.to eq task3 }
    end
    context "when there are completed organization tasks without child tasks" do
      let(:judge) { create(:user) }
      let(:appeal) { create(:appeal) }
      let!(:task) { create(:ama_judge_task, assigned_to: judge, appeal: appeal) }
      let!(:task2) do
        create(:qr_task, appeal: appeal, status: Constants.TASK_STATUSES.completed, assigned_to_type: "Organization")
      end

      subject { appeal.tasks_for_timeline.first }
      it { is_expected.to eq task2 }
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
end
