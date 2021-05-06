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
            representative_name: Fakes::BGSServicePOA::PARALYZED_VETERANS_VSO_NAME,
            representative_type: Fakes::BGSServicePOA::POA_NATIONAL_ORGANIZATION,
            participant_id: Fakes::BGSServicePOA::PARALYZED_VETERANS_VSO_PARTICIPANT_ID,
            file_number: "66660000"
          }
        )
      allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
        .with([participant_id_with_aml]).and_return(
          participant_id_with_aml => {
            representative_name: Fakes::BGSServicePOA::VIETNAM_VETERANS_VSO_NAME,
            representative_type: Fakes::BGSServicePOA::POA_NATIONAL_ORGANIZATION,
            participant_id: Fakes::BGSServicePOA::VIETNAM_VETERANS_VSO_PARTICIPANT_ID,
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
        participant_id: Fakes::BGSServicePOA::PARALYZED_VETERANS_VSO_PARTICIPANT_ID
      )
    end

    context "when an original appeal" do
      context "on the direct docket is created" do
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

        context "on veteran date of death present" do
          let(:appeal) do
            create(
              :appeal,
              docket_type: Constants.AMA_DOCKETS.direct_review,
              claimants: [ create(:claimant, participant_id: participant_id_with_no_vso) ],
              veteran: create(:veteran, date_of_death: 30.days.ago.to_date)
            )
          end

          it "is ready for distribution" do
            InitialTasksFactory.new(appeal).create_root_and_sub_tasks!

            expect(DistributionTask.find_by(appeal: appeal).status).to eq("assigned")
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

      context "on the evidence submission docket is created" do
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

      context "on the hearing docket is created" do
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

          before do
            allow_any_instance_of(Representative).to receive(:should_write_ihp?).with(anything).and_return(false)
          end

          it "creates no IHP tasks" do
            InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
            expect(InformalHearingPresentationTask.find_by(appeal: appeal)).to be_nil
          end
        end
      end
    end

    context "when a Court Remand appeal stream is created" do
      # create(:cavc_remand, ...) indirectly calls InitialTasksFactory#create_root_and_sub_tasks!
      subject do
        create(:cavc_remand,
               source_appeal: appeal,
               cavc_decision_type: cavc_decision_type,
               remand_subtype: remand_subtype,
               judgement_date: judgement_date,
               mandate_date: mandate_date)
      end

      let(:cavc_decision_type) { Constants.CAVC_DECISION_TYPES.remand }
      let(:judgement_date) { 30.days.ago.to_date }
      let(:mandate_date) { 30.days.ago.to_date }

      before do
        expect_any_instance_of(InitialTasksFactory).to receive(:create_root_and_sub_tasks!).once.and_call_original
        expect_any_instance_of(InitialTasksFactory).to receive(:create_cavc_subtasks).once.and_call_original
      end

      shared_examples "remand appeal blocking distribution" do |some_task_class, some_task_status|
        it "blocks distribution with a CavcTask" do
          remand_appeal = subject.remand_appeal

          expect(DistributionTask.find_by(appeal: remand_appeal).status).to eq("on_hold")
          expect(CavcTask.find_by(appeal: remand_appeal).parent.class.name).to eq("DistributionTask")
          expect(CavcTask.find_by(appeal: remand_appeal).status).to eq("on_hold")
          expect(remand_appeal.tasks.count { |t| t.is_a?(TrackVeteranTask) }).to eq(1)

          expect(some_task_class.find_by(appeal: remand_appeal).status).to eq(some_task_status)
        end
      end

      context "when CavcRemand subtype is JMR or JMPR" do
        let(:remand_subtype) { Constants.CAVC_REMAND_SUBTYPES.jmpr }

        include_examples "remand appeal blocking distribution", SendCavcRemandProcessedLetterTask, "assigned"
      end

      context "when CavcRemand subtype is MDR" do
        let(:remand_subtype) { Constants.CAVC_REMAND_SUBTYPES.mdr }

        include_examples "remand appeal blocking distribution", MdrTask, "on_hold"
      end

      shared_examples "creates mandate hold task if needed" do
        let(:remand_subtype) { nil }

        it "sets appeal ready for distribution" do
          remand_appeal = subject.remand_appeal

          expect(DistributionTask.find_by(appeal: remand_appeal).status).to eq("assigned")
          expect(MandateHoldTask.find_by(appeal: remand_appeal)).to be_nil
          expect(CavcTask.find_by(appeal: remand_appeal)).to be_nil
          expect(remand_appeal.tasks.count { |t| t.is_a?(TrackVeteranTask) }).to eq(1)
        end

        context "when mandate dates are not provided" do
          let(:judgement_date) { nil }
          let(:mandate_date) { nil }

          include_examples "remand appeal blocking distribution", MandateHoldTask, "on_hold"
        end

        context "when either of the mandate dates is not provided" do
          let(:judgement_date) { [nil, 30.days.ago.to_date].sample }
          let(:mandate_date) { 30.days.ago.to_date if judgement_date.nil? }

          include_examples "remand appeal blocking distribution", MandateHoldTask, "on_hold"
        end
      end

      context "when CavcRemand decision type is straight_reversal" do
        let(:cavc_decision_type) { Constants.CAVC_DECISION_TYPES.straight_reversal }
        include_examples "creates mandate hold task if needed"
      end

      context "when CavcRemand decision type is death_dismissal" do
        let(:cavc_decision_type) { Constants.CAVC_DECISION_TYPES.death_dismissal }
        include_examples "creates mandate hold task if needed"
      end
    end
  end
end
