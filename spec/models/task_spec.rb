describe Task do
  describe ".when_child_task_completed" do
    context "when on_hold task is assigned to a person" do
      let(:task) { FactoryBot.create(:task, :on_hold, type: "Task") }
      context "when task has no child tasks" do
        it "should not change the task's status" do
          status_before = task.status
          task.when_child_task_completed
          expect(task.status).to eq(status_before)
        end
      end

      context "when task has 1 incomplete child task" do
        before { FactoryBot.create(:task, :in_progress, type: "Task", parent_id: task.id) }
        it "should not change the task's status" do
          status_before = task.status
          task.when_child_task_completed
          expect(task.status).to eq(status_before)
        end
      end

      context "when task has 1 complete child task" do
        before { FactoryBot.create(:task, :completed, type: "Task", parent_id: task.id) }
        it "should change task's status to assigned" do
          status_before = task.status
          task.when_child_task_completed
          expect(task.status).to_not eq(status_before)
          expect(task.status).to eq("assigned")
        end
      end

      context "when task has some complete and some incomplete child tasks" do
        before do
          FactoryBot.create_list(:task, 3, :completed, type: "Task", parent_id: task.id)
          FactoryBot.create_list(:task, 2, :in_progress, type: "Task", parent_id: task.id)
        end
        it "should not change the task's status" do
          status_before = task.status
          task.when_child_task_completed
          expect(task.status).to eq(status_before)
        end
      end

      context "when task has only complete child tasks" do
        before { FactoryBot.create_list(:task, 4, :completed, type: "Task", parent_id: task.id) }
        it "should change task's status to assigned" do
          status_before = task.status
          task.when_child_task_completed
          expect(task.status).to_not eq(status_before)
          expect(task.status).to eq("assigned")
        end
      end
    end

    context "when on_hold task is assigned to an organization" do
      let(:organization) { Organization.create! }
      let(:task) { FactoryBot.create(:task, :on_hold, type: "Task", assigned_to: organization) }
      context "when task has no child tasks" do
        it "should not call mark_as_complete!" do
          expect_any_instance_of(Task).to_not receive(:mark_as_complete!)
          task.when_child_task_completed
        end
      end

      context "when task has 1 incomplete child task" do
        before { FactoryBot.create(:task, :in_progress, type: "Task", parent_id: task.id) }
        it "should not call mark_as_complete!" do
          expect_any_instance_of(Task).to_not receive(:mark_as_complete!)
          task.when_child_task_completed
        end
      end

      context "when task has 1 complete child task" do
        before { FactoryBot.create(:task, :completed, type: "Task", parent_id: task.id) }
        it "should call mark_as_complete!" do
          expect_any_instance_of(Task).to receive(:mark_as_complete!)
          task.when_child_task_completed
        end
      end

      context "when task has some complete and some incomplete child tasks" do
        before do
          FactoryBot.create_list(:task, 3, :completed, type: "Task", parent_id: task.id)
          FactoryBot.create_list(:task, 2, :in_progress, type: "Task", parent_id: task.id)
        end
        it "should not call mark_as_complete!" do
          expect_any_instance_of(Task).to_not receive(:mark_as_complete!)
          task.when_child_task_completed
        end
      end

      context "when task has only complete child tasks" do
        before { FactoryBot.create_list(:task, 4, :completed, type: "Task", parent_id: task.id) }
        it "should call mark_as_complete!" do
          expect_any_instance_of(Task).to receive(:mark_as_complete!)
          task.when_child_task_completed
        end
      end
    end
  end

  context "#prepared_by_display_name" do
    let(:task) { create(:task, type: "Task") }

    context "when there is no attorney_case_review" do
      it "should return nil" do
        expect(task.prepared_by_display_name).to eq(nil)
      end
    end

    context "when there is an attorney_case_review" do
      let!(:child) { create(:task, type: "Task", parent_id: task.id) }
      let!(:attorney_case_reviews) do
          create(:attorney_case_review, task_id: child.id, attorney: create(:user, full_name: "Bob Smith"))
      end

      it "should return the most recent attorney case review" do
        expect(task.prepared_by_display_name).to eq(["Bob", "Smith"])
      end
    end
  end

  context "#latest_attorney_case_review" do
    let(:task) { create(:task, type: "Task") }

    context "when there is no sub task" do
      it "should return nil" do
        expect(task.latest_attorney_case_review).to eq(nil)
      end
    end

    context "when there is a sub task" do
      let!(:child) { create(:task, type: "Task", parent_id: task.id) }
      let!(:attorney_case_reviews) do
        [
          create(:attorney_case_review, task_id: child.id, created_at: 1.day.ago),
          create(:attorney_case_review, task_id: child.id, created_at: 2.day.ago)
        ]
      end

      it "should return the most recent attorney case review" do
        expect(task.latest_attorney_case_review).to eq(attorney_case_reviews.first)
      end
    end
  end

  describe ".root_task" do
    context "when sub-sub-sub...task has a root task" do
      let(:root_task) { FactoryBot.create(:root_task) }
      let(:task) do
        t = FactoryBot.create(:generic_task, parent_id: root_task.id)
        5.times { t = FactoryBot.create(:generic_task, parent_id: t.id) }
        GenericTask.last
      end

      it "should return the root_task" do
        expect(task.root_task.id).to eq(root_task.id)
      end
    end

    context "when sub-sub-sub...task does not have a root task" do
      let(:task) do
        t = FactoryBot.create(:generic_task)
        5.times { t = FactoryBot.create(:generic_task, parent_id: t.id) }
        GenericTask.last
      end

      it "should throw an error" do
        expect { task.root_task }.to(raise_error) do |e|
          expect(e).to be_a(Caseflow::Error::NoRootTask)
          expect(e.message).to eq("Could not find root task for task with ID #{task.id}")
        end
      end
    end

    context "task is root task" do
      let(:task) { FactoryBot.create(:root_task) }
      it "should return itself" do
        expect(task.root_task.id).to eq(task.id)
      end
    end
  end
end
