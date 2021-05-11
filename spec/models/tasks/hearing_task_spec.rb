# frozen_string_literal: true

describe HearingTask, :postgres do
  describe ".create_change_hearing_disposition_task" do
    let(:appeal) { create(:appeal) }
    let(:root_task) { create(:root_task, appeal: appeal) }
    let(:hearing_task) { create(:hearing_task, parent: root_task) }
    let(:instructions) { "These are the instructions I've written for you." }
    let!(:disposition_task) do
      create(
        :assign_hearing_disposition_task,
        :in_progress,
        parent: hearing_task
      )
    end
    let!(:transcription_task) { create(:transcription_task, parent: disposition_task) }

    subject { hearing_task.create_change_hearing_disposition_task(instructions) }

    it "completes the disposition task and its children and creates a new change hearing disposition task" do
      expect(disposition_task.status).to_not eq Constants.TASK_STATUSES.completed
      expect(ChangeHearingDispositionTask.count).to eq 0

      subject

      expect(disposition_task.reload.status).to eq Constants.TASK_STATUSES.completed
      expect(transcription_task.reload.status).to eq Constants.TASK_STATUSES.completed
      expect(ChangeHearingDispositionTask.count).to eq 1
      change_hearing_disposition_task = ChangeHearingDispositionTask.last
      expect(change_hearing_disposition_task.appeal).to eq appeal
      expect(change_hearing_disposition_task.parent).to eq hearing_task
      expect(change_hearing_disposition_task.open?).to be_truthy
      expect(change_hearing_disposition_task.instructions).to include(instructions)
    end
  end

  describe ".assign_hearing_disposition_task" do
    let(:root_task) { create(:root_task) }
    let(:hearing_task) { create(:hearing_task, parent: root_task) }
    let(:disposition_task_type) { :assign_hearing_disposition_task }
    let(:trait) { :assigned }
    let!(:disposition_task) do
      create(
        disposition_task_type,
        trait,
        parent: hearing_task
      )
    end

    subject { hearing_task.disposition_task }

    it "returns the disposition task" do
      expect(subject).to eq disposition_task
    end

    context "the disposition task is not active" do
      let(:trait) { :cancelled }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "it's a ChangeHearingDispositionTask" do
      let(:disposition_task_type) { :change_hearing_disposition_task }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe ".when_child_task_completed" do
    let(:veteran_pid) { "0000" }
    let(:disposition) { nil }
    let(:veteran) { create(:veteran, participant_id: veteran_pid) }
    let(:root_task) { create(:root_task, appeal: appeal) }
    let(:hearing_task) { create(:hearing_task, appeal: appeal, parent: root_task) }
    let!(:association) { create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task) }
    let!(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal, parent: hearing_task) }

    subject { schedule_hearing_task.completed! }

    context "legacy appeal" do
      let(:loc_caseflow) { LegacyAppeal::LOCATION_CODES[:caseflow] }
      let(:loc_transcription) { LegacyAppeal::LOCATION_CODES[:transcription] }
      let(:loc_service_org) { LegacyAppeal::LOCATION_CODES[:service_organization] }
      let(:loc_case_storage) { LegacyAppeal::LOCATION_CODES[:case_storage] }

      let(:vacols_case) { create(:case, bfcurloc: loc_caseflow) }
      let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
      let!(:hearing) { create(:legacy_hearing, appeal: appeal, disposition: disposition) }
      let(:representative_pid) { "1234" }

      let(:lar) { double("LegacyAppealRepresentative") }

      before do
        allow(LegacyAppealRepresentative).to receive(:new).and_return(lar)
      end

      context "hearing is held" do
        let(:disposition) { VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:held] }

        it "moves the appeal to transcription" do
          expect { subject }.to change { vacols_case.reload.bfcurloc }.from(loc_caseflow).to(loc_transcription)
        end
      end

      context "representative is a vso" do
        context "representative is not a colocated vso" do
          it "moves the appeal to case storage" do
            allow(lar).to receive(:representative_is_colocated_vso?).and_return(false)

            expect { subject }.to change { vacols_case.reload.bfcurloc }.from(loc_caseflow).to(loc_case_storage)
          end
        end

        context "representative is a colocated vso" do
          it "moves the appeal to service organization" do
            allow(lar).to receive(:representative_is_colocated_vso?).and_return(true)

            expect { subject }.to change { vacols_case.reload.bfcurloc }.from(loc_caseflow).to(loc_service_org)
          end
        end
      end
    end

    context "ama appeal" do
      let(:appeal) { create(:appeal, veteran_file_number: veteran.file_number) }
      let!(:hearing) { create(:hearing, appeal: appeal, disposition: nil) }
      let!(:vso) do
        Vso.create(
          name: "Paralyzed Veterans Of America",
          role: "VSO",
          url: "paralyzed-veterans-of-america",
          participant_id: Fakes::BGSServicePOA::PARALYZED_VETERANS_VSO_PARTICIPANT_ID
        )
      end

      before do
        allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids).with([veteran_pid]) do
          { veteran_pid => Fakes::BGSServicePOA.paralyzed_veterans_vso_mapped }
        end
      end

      it "creates IHP tasks" do
        expect { subject }.to change(InformalHearingPresentationTask, :count).by 1
      end

      context "there is another open HearingTask" do
        let!(:another_hearing_task) { create(:hearing_task, parent: root_task) }

        it "does not create IHP tasks" do
          expect { subject }.to_not change(InformalHearingPresentationTask, :count)
        end
      end
    end
  end

  describe ".update_from_params" do
    let(:hearings_management_user) { create(:hearings_coordinator) }
    let(:notes) { "New notes" }
    let(:hearing_task) { create(:hearing_task, appeal: appeal) }
    let(:update_params) do
      {
        business_payloads: {
          values: {
            notes: notes
          }
        }
      }
    end

    before { HearingsManagement.singleton.add_user(hearings_management_user) }

    subject { hearing_task.update_from_params(update_params, hearings_management_user) }

    context "with notes as param" do
      context "for ama appeal" do
        let(:appeal) { create(:appeal) }

        it "updates value correctly", :aggregate_failures do
          expect(subject.count).to eq(1)
          expect(hearing_task.reload.instructions).to match_array([notes])
          expect(hearing_task.versions.count).to eq(1)
        end
      end

      context "for legacy appeal", :aggregate_failures do
        let(:appeal) { create(:legacy_appeal) }

        it "updates value correctly" do
          expect(subject.count).to eq(1)
          expect(hearing_task.reload.instructions).to match_array([notes])
          expect(hearing_task.versions.count).to eq(1)
        end
      end
    end
  end

  describe ".unscheduled_hearing_notes" do
    let(:appeal) { create(:appeal) }
    let(:instructions) { ["Notes"] }
    let(:hearing_task) { create(:hearing_task, instructions: instructions, appeal: appeal) }

    subject { hearing_task.unscheduled_hearing_notes }

    context "with no paper trail versions but a value for instructions" do
      it "returns correct value" do
        expect(subject).to eq(
          notes: instructions.first,
          updated_at: nil,
          updated_by_css_id: nil
        )
      end
    end

    context "with a paper trail version and value for instructions" do
      before do
        hearing_task.update!(instructions: ["New notes"])
      end

      it "returns correct value" do
        expect(subject).to eq(
          notes: "New notes",
          updated_at: hearing_task.reload.versions.first.created_at,
          updated_by_css_id: nil
        )
      end
    end

    context "with neither paper trail version and nor value for instructions" do
      let(:instructions) { nil }

      it "returns correct value" do
        expect(subject).to eq(
          notes: nil,
          updated_at: nil,
          updated_by_css_id: nil
        )
      end
    end
  end
end
