# frozen_string_literal: true

describe TrackVeteranTask, :postgres do
  let(:vso) { create(:vso) }
  let(:root_task) { create(:root_task) }
  let(:tracking_task) do
    create(
      :track_veteran_task,
      parent: root_task,
      assigned_to: vso
    )
  end

  describe ".create!" do
    it "sets the status of the task to in_progress" do
      task = TrackVeteranTask.create(parent: root_task, appeal: root_task.appeal, assigned_to: vso)
      expect(task.status).to eq(Constants.TASK_STATUSES.in_progress)
    end
  end

  describe ".available_actions" do
    it "should never have available_actions" do
      expect(tracking_task.available_actions(vso)).to eq([])
    end
  end

  describe ".hide_from_queue_table_view" do
    it "should always be hidden from queue table view" do
      expect(tracking_task.hide_from_queue_table_view).to eq(true)
    end
  end

  describe ".hide_from_case_timeline" do
    it "should always be hidden from case timeline" do
      expect(tracking_task.hide_from_case_timeline).to eq(true)
    end
  end

  describe ".hide_from_task_snapshot" do
    it "should always be hidden from task snapshot" do
      expect(tracking_task.hide_from_case_timeline).to eq(true)
    end
  end

  describe ".sync_tracking_tasks" do
    let!(:appeal) { create(:appeal) }
    let!(:root_task) { create(:root_task, appeal: appeal) }

    subject { TrackVeteranTask.sync_tracking_tasks(appeal) }

    context "When former represenative VSO is assigned non-Tracking tasks" do
      let!(:old_vso) { create(:vso, name: "Remember Korea") }
      let!(:new_vso) { create(:vso) }
      let!(:root_task) { create(:root_task, appeal: appeal) }

      let!(:ihp_org_task) do
        create(:informal_hearing_presentation_task, appeal: appeal, assigned_to: old_vso)
      end
      let!(:tracking_task) do
        create(
          :track_veteran_task,
          parent: root_task,
          appeal: root_task.appeal,
          assigned_to: old_vso
        )
      end

      before { allow_any_instance_of(Appeal).to receive(:representatives).and_return([new_vso]) }

      it "cancels all tasks of former VSO" do
        subject
        expect(ihp_org_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
      end

      it "makes duplicates of active tasks for new representation" do
        expect(new_vso.tasks.count).to eq(0)
        expect(subject).to eq([1, 2])
        expect(new_vso.tasks.count).to eq(2)
      end

      context "When there's an open Distribution Task" do
        let!(:dist_task) { create(:distribution_task, appeal: appeal) }
        it "IHP Task is a child of the Distribution Task" do
          subject
          new_ihp_task = InformalHearingPresentationTask.find_by(assigned_to: new_vso)
          expect(dist_task.status).to eq("on_hold")
          expect(new_ihp_task.parent).to eq(dist_task)
        end
      end
    end
    context "when the appeal has no VSOs" do
      before { allow_any_instance_of(Appeal).to receive(:representatives).and_return([]) }

      context "when there are no existing TrackVeteranTasks" do
        it "does not create or cancel any TrackVeteranTasks" do
          task_count_before = TrackVeteranTask.count

          expect(subject).to eq([0, 0])
          expect(TrackVeteranTask.count).to eq(task_count_before)
        end
      end

      context "when there is an existing open TrackVeteranTasks" do
        let(:vso) { create(:vso) }
        let!(:tracking_task) { create(:track_veteran_task, appeal: appeal, assigned_to: vso) }

        it "cancels old TrackVeteranTask, does not create any new tasks" do
          active_task_count_before = TrackVeteranTask.open.count

          expect(subject).to eq([0, 1])
          expect(TrackVeteranTask.open.count).to eq(active_task_count_before - 1)
        end
      end
    end

    context "when the appeal has two VSOs" do
      let(:representing_vsos) { create_list(:vso, 2) }
      before { allow_any_instance_of(Appeal).to receive(:representatives).and_return(representing_vsos) }

      context "when there are no existing TrackVeteranTasks" do
        it "creates 2 new TrackVeteranTasks and 2 IHP Tasks" do
          task_count_before = TrackVeteranTask.count

          expect(subject).to eq([2, 0])
          expect(TrackVeteranTask.count).to eq(task_count_before + 2)
        end
      end

      context "when there is an existing open TrackVeteranTasks for a different VSO" do
        before do
          create(:track_veteran_task, appeal: appeal, assigned_to: create(:vso))
        end

        it "cancels old TrackVeteranTask, creates 2 new TrackVeteran and 2 new IHP tasks" do
          expect(subject).to eq([2, 1])
        end
      end

      context "when there are already TrackVeteranTasks for both VSOs" do
        before do
          representing_vsos.each do |vso|
            create(:track_veteran_task, appeal: appeal, assigned_to: vso)
          end
        end

        it "does not create or cancel any TrackVeteranTasks" do
          task_count_before = TrackVeteranTask.count

          expect(subject).to eq([0, 0])
          expect(TrackVeteranTask.count).to eq(task_count_before)
        end
      end
    end

    context "when an IHP task has been assigned to an individual person" do
      let(:vso) { create(:vso) }
      let(:vso_staff) { create(:user) }
      let(:org_ihp_task) do
        create(:informal_hearing_presentation_task, parent: root_task, assigned_to: vso)
      end
      let!(:individual_ihp_task) do
        create(
          :informal_hearing_presentation_task,
          appeal: appeal,
          parent: org_ihp_task,
          assigned_to: vso_staff
        )
      end

      before do
        vso.add_user(vso_staff)
      end

      context "when the individual's VSO is still the representative" do
        before { allow_any_instance_of(Appeal).to receive(:representatives).and_return([vso]) }

        it "leaves the individually-assigned IHP task open after syncing tracking tasks" do
          expect(individual_ihp_task.status).to eq(Constants.TASK_STATUSES.assigned)
          subject
          expect(individual_ihp_task.reload.status).to eq(Constants.TASK_STATUSES.assigned)
        end
      end

      context "when the individual's VSO no longer represents the appellant" do
        it "closes the individually-assigned IHP task" do
          expect(individual_ihp_task.status).to eq(Constants.TASK_STATUSES.assigned)
          subject
          expect(individual_ihp_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
        end
      end
    end
  end
end
