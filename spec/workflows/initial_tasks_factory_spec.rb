# frozen_string_literal: true

describe InitialTasksFactory, :postgres do
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
            participant_id: "2452383",
            file_number: "66660000"
          }
        )
      allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
        .with([participant_id_with_aml]).and_return(
          participant_id_with_aml => {
            representative_name: "VIETNAM VETERANS OF AMERICA",
            representative_type: "POA National Organization",
            participant_id: "2452415",
            file_number: "66661111"
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
      context "when it has no vso representation" do
        let(:appeal) do
          create(:appeal, docket_type: Constants.AMA_DOCKETS.direct_review, claimants: [
                   create(:claimant, participant_id: participant_id_with_no_vso)
                 ])
        end

        before { InitialTasksFactory.new(appeal).create_root_and_sub_tasks! }

        it "is ready for distribution immediately" do
          expect(DistributionTask.find_by(appeal: appeal).status).to eq("assigned")
        end

        it "does not create a tracking task" do
          expect(appeal.tasks.count { |t| t.is_a?(TrackVeteranTask) }).to eq(0)
        end
      end

      context "when it has an ihp-writing vso" do
        let(:appeal) do
          create(:appeal, docket_type: Constants.AMA_DOCKETS.direct_review, claimants: [
                   create(:claimant, participant_id: participant_id_with_pva),
                   create(:claimant, participant_id: participant_id_with_aml)
                 ])
        end

        subject { InitialTasksFactory.new(appeal).create_root_and_sub_tasks! }

        it "blocks distribution" do
          subject
          expect(DistributionTask.find_by(appeal: appeal).status).to eq("on_hold")
        end

        it "requires an informal hearing presentation" do
          subject
          expect(InformalHearingPresentationTask.find_by(appeal: appeal).status).to eq("assigned")
          expect(InformalHearingPresentationTask.find_by(appeal: appeal).parent.class.name).to eq("DistributionTask")
        end

        it "creates a tracking task assigned to the VSO" do
          subject
          expect(appeal.tasks.count { |t| t.is_a?(TrackVeteranTask) }).to eq(1)
          expect(appeal.tasks.detect { |t| t.is_a?(TrackVeteranTask) }.assigned_to).to eq(pva)
        end

        it "doesn't create a InformalHearingPresentationTask for missing organization" do
          subject
          expect(InformalHearingPresentationTask.count).to eq(1)
          expect(InformalHearingPresentationTask.first.assigned_to).to eq(pva)
        end

        context "when a TrackVeteranTask already exists for the appeal and representative" do
          before do
            root_task = RootTask.create!(appeal: appeal)
            TrackVeteranTask.create!(appeal: appeal, parent: root_task, assigned_to: pva)
          end

          it "does not create a duplicate tracking task" do
            expect(appeal.tasks.count { |t| t.is_a?(TrackVeteranTask) }).to eq(1)
            subject
            expect(appeal.reload.tasks.count { |t| t.is_a?(TrackVeteranTask) }).to eq(1)
          end
        end
      end
    end

    context "when it has multiple ihp-writing vsos" do
      let!(:vva) do
        Vso.create(
          name: "Vietnam Veterans Of America",
          role: "VSO",
          url: "vietnam-veterans-of-america",
          participant_id: "2452415"
        )
      end

      let(:appeal) do
        create(:appeal, docket_type: Constants.AMA_DOCKETS.direct_review, claimants: [
                 create(:claimant, participant_id: participant_id_with_pva),
                 create(:claimant, participant_id: participant_id_with_aml)
               ])
      end

      it "creates a task for each VSO" do
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
        expect(RootTask.count).to eq(1)

        expect(InformalHearingPresentationTask.count).to eq(2)
        # sort order is non-deterministic so load by assignee
        expect(pva.tasks.map(&:type)).to include("InformalHearingPresentationTask")
        expect(vva.tasks.map(&:type)).to include("InformalHearingPresentationTask")
      end

      it "does not create a task for a VSO if one already exists for that appeal" do
        InformalHearingPresentationTask.create!(
          appeal: appeal,
          parent: appeal.root_task,
          assigned_to: vva
        )
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!

        expect(InformalHearingPresentationTask.count).to eq(2)
        # sort order is non-deterministic so load by assignee
        expect(pva.tasks.map(&:type)).to include("InformalHearingPresentationTask")
        expect(vva.tasks.map(&:type)).to include("InformalHearingPresentationTask")
      end

      it "creates RootTask assigned to Bva organization" do
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
        expect(RootTask.last.assigned_to).to eq(Bva.singleton)
      end
    end

    context "when an evidence submission docket appeal is created" do
      let(:appeal) do
        create(:appeal, docket_type: Constants.AMA_DOCKETS.evidence_submission, claimants: [
                 create(:claimant, participant_id: participant_id_with_no_vso)
               ])
      end

      it "blocks distribution" do
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
        expect(DistributionTask.find_by(appeal: appeal).status).to eq("on_hold")
        expect(EvidenceSubmissionWindowTask.find_by(appeal: appeal).parent.class.name).to eq("DistributionTask")
      end
    end

    context "when a hearing docket appeal is created" do
      let(:appeal) do
        create(:appeal, docket_type: Constants.AMA_DOCKETS.hearing, claimants: [
                 create(:claimant, participant_id: participant_id_with_no_vso)
               ])
      end

      it "blocks distribution with schedule hearing task" do
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
        expect(DistributionTask.find_by(appeal: appeal).status).to eq("on_hold")
        expect(ScheduleHearingTask.find_by(appeal: appeal).parent.class.name).to eq("HearingTask")
        expect(ScheduleHearingTask.find_by(appeal: appeal).parent.parent.class.name).to eq("DistributionTask")
      end

      context "when VSO does not writes IHPs for hearing docket cases" do
        let(:appeal) do
          create(
            :appeal,
            docket_type: Constants.AMA_DOCKETS.hearing,
            claimants: [create(:claimant, participant_id: participant_id_with_pva)]
          )
        end

        before { allow_any_instance_of(Representative).to receive(:should_write_ihp?).with(anything).and_return(false) }

        it "creates no IHP tasks" do
          InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
          expect(InformalHearingPresentationTask.find_by(appeal: appeal)).to be_nil
        end
      end
    end
  end
end
