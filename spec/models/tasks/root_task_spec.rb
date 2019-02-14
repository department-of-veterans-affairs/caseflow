describe RootTask do
  context ".create_root_and_sub_tasks!" do
    let(:participant_id_with_pva) { "1234" }
    let(:participant_id_with_aml) { "5678" }
    let(:participant_id_with_no_vso) { "9999" }

    let(:appeal) do
      create(:appeal, claimants: [
               create(:claimant, participant_id: participant_id_with_pva),
               create(:claimant, participant_id: participant_id_with_aml)
             ])
    end

    before do
      allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
        .with([participant_id_with_pva]).and_return(
          participant_id_with_pva => {
            representative_name: "PARALYZED VETERANS OF AMERICA, INC.",
            representative_type: "POA National Organization",
            participant_id: "2452383"
          }
        )
      allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
        .with([participant_id_with_aml]).and_return(
          participant_id_with_aml => {
            representative_name: "VIETNAM VETERANS OF AMERICA",
            representative_type: "POA National Organization",
            participant_id: "2452415"
          }
        )
      allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
        .with([participant_id_with_no_vso]).and_return({})
    end

    let!(:pva) do
      Vso.create(
        name: "Paralyzed Veterans Of America",
        role: "VSO",
        url: "paralyzed-veterans-of-america",
        participant_id: "2452383"
      )
    end

    context "when a direct docket appeal is created" do
      before do
        FeatureToggle.enable!(:ama_auto_case_distribution)
      end
      after do
        FeatureToggle.disable!(:ama_auto_case_distribution)
      end
      context "when it has no vso representation" do
        let(:appeal) do
          create(:appeal, docket_type: "direct_docket", claimants: [
                   create(:claimant, participant_id: participant_id_with_no_vso)
                 ])
        end

        before { RootTask.create_root_and_sub_tasks!(appeal) }

        it "is ready for distribution immediately" do
          expect(DistributionTask.find_by(appeal: appeal).status).to eq("assigned")
        end

        it "does not create a tracking task" do
          expect(appeal.tasks.select { |t| t.is_a?(TrackVeteranTask) }.length).to eq(0)
        end
      end

      context "when it has an ihp-writing vso" do
        let(:appeal) do
          create(:appeal, docket_type: "direct_docket", claimants: [
                   create(:claimant, participant_id: participant_id_with_pva),
                   create(:claimant, participant_id: participant_id_with_aml)
                 ])
        end

        before { RootTask.create_root_and_sub_tasks!(appeal) }

        it "blocks distribution" do
          expect(DistributionTask.find_by(appeal: appeal).status).to eq("on_hold")
        end

        it "requires an informal hearing presentation" do
          expect(InformalHearingPresentationTask.find_by(appeal: appeal).status).to eq("assigned")
          expect(InformalHearingPresentationTask.find_by(appeal: appeal).parent.class.name).to eq("DistributionTask")
        end

        it "creates a tracking task assigned to the VSO" do
          expect(appeal.tasks.select { |t| t.is_a?(TrackVeteranTask) }.length).to eq(1)
          expect(appeal.tasks.detect { |t| t.is_a?(TrackVeteranTask) }.assigned_to).to eq(pva)
        end
      end
    end

    context "when an evidence submission docket appeal is created" do
      before do
        FeatureToggle.enable!(:ama_auto_case_distribution)
      end
      after do
        FeatureToggle.disable!(:ama_auto_case_distribution)
      end
      let(:appeal) do
        create(:appeal, docket_type: "evidence_submission", claimants: [
                 create(:claimant, participant_id: participant_id_with_no_vso)
               ])
      end

      it "blocks distribution" do
        RootTask.create_root_and_sub_tasks!(appeal)
        expect(DistributionTask.find_by(appeal: appeal).status).to eq("on_hold")
        expect(EvidenceSubmissionWindowTask.find_by(appeal: appeal).parent.class.name).to eq("DistributionTask")
      end
    end

    context "when a hearing docket appeal is created" do
      before do
        FeatureToggle.enable!(:ama_auto_case_distribution)
      end
      after do
        FeatureToggle.disable!(:ama_auto_case_distribution)
      end
      let(:appeal) do
        create(:appeal, docket_type: "hearing", claimants: [
                 create(:claimant, participant_id: participant_id_with_no_vso)
               ])
      end

      it "blocks distribution with schedule hearing task" do
        RootTask.create_root_and_sub_tasks!(appeal)
        expect(DistributionTask.find_by(appeal: appeal).status).to eq("on_hold")
        expect(ScheduleHearingTask.find_by(appeal: appeal).parent.class.name).to eq("HearingTask")
        expect(ScheduleHearingTask.find_by(appeal: appeal).parent.parent.class.name).to eq("DistributionTask")
      end
    end

    context "when VSOs exist in our organization table" do
      let!(:vva) do
        Vso.create(
          name: "Vietnam Veterans Of America",
          role: "VSO",
          url: "vietnam-veterans-of-america",
          participant_id: "2452415"
        )
      end

      it "creates a task for each VSO" do
        RootTask.create_root_and_sub_tasks!(appeal)
        expect(RootTask.count).to eq(1)

        expect(InformalHearingPresentationTask.count).to eq(2)
        expect(InformalHearingPresentationTask.first.assigned_to).to eq(pva)
        expect(InformalHearingPresentationTask.second.assigned_to).to eq(vva)
      end

      it "creates RootTask assigned to Bva organization" do
        RootTask.create_root_and_sub_tasks!(appeal)
        expect(RootTask.last.assigned_to).to eq(Bva.singleton)
      end
    end

    context "when only one VSO exists in our organization table" do
      it "doesn't create a InformalHearingPresentationTask for missing organization" do
        RootTask.create_root_and_sub_tasks!(appeal)

        expect(InformalHearingPresentationTask.count).to eq(1)
        expect(InformalHearingPresentationTask.first.assigned_to).to eq(pva)
      end
    end
  end

  describe ".available_actions_unwrapper" do
    let(:user) { FactoryBot.create(:user) }
    let(:root_task) { RootTask.find(FactoryBot.create(:root_task).id) }

    subject { root_task.available_actions_unwrapper(user) }

    context "when user is a member of the Mail team" do
      before { allow_any_instance_of(MailTeam).to receive(:user_has_access?).and_return(true) }

      it "should return a list that includes only the create mail task" do
        expect(subject).to eq([root_task.build_action_hash(Constants.TASK_ACTIONS.CREATE_MAIL_TASK.to_h, user)])
      end
    end

    context "when user is not a member of the Mail team" do
      it "should return an empty list" do
        expect(subject).to eq([])
      end
    end
  end

  describe ".update_children_status" do
    let!(:root_task) { FactoryBot.create(:root_task) }
    let!(:appeal) { root_task.appeal }

    subject { root_task.update_children_status }

    context "when there are multiple children tasks" do
      let!(:generic_task) { FactoryBot.create(:generic_task, appeal: appeal, parent: root_task) }
      let!(:tracking_task) { FactoryBot.create(:track_veteran_task, appeal: appeal, parent: root_task) }

      it "should close the tracking task but not the generic task" do
        expect { subject }.to_not raise_error
        expect(tracking_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        expect(generic_task.reload.status).to_not eq(Constants.TASK_STATUSES.completed)
      end
    end
  end

  describe ".set_assignee" do
    context "when retrieving an existing RootTask" do
      let!(:root_task) { FactoryBot.create(:root_task, assigned_to: assignee) }
      context "when the assignee is already set" do
        let(:assignee) { Bva.singleton }

        it "should not be called" do
          expect_any_instance_of(RootTask).to_not receive(:set_assignee)

          RootTask.find(root_task.id)
        end
      end
    end

    context "when creating a new RootTask" do
      context "when the assignee is already set" do
        it "should not be called" do
          expect_any_instance_of(RootTask).to_not receive(:set_assignee)

          RootTask.create(appeal: FactoryBot.create(:appeal), assigned_to: Bva.singleton)
        end
      end

      context "when the assignee is not set" do
        it "should not be called" do
          expect_any_instance_of(RootTask).to receive(:set_assignee).exactly(1).times

          RootTask.create(appeal: FactoryBot.create(:appeal))
        end
      end
    end
  end
end
