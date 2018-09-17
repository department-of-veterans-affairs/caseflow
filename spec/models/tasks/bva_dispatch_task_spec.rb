describe BvaDispatchTask do
  before { FeatureToggle.enable!(:test_facols) }
  after { FeatureToggle.disable!(:test_facols) }

  describe ".create_and_assign" do
    context "when no root_task passed as argument" do
      it "throws an error" do
        expect { BvaDispatchTask.create_and_assign(nil) }.to raise_error(NoMethodError)
      end
    end

    context "when valid root_task passed as argument" do
      let(:root_task) { FactoryBot.create(:root_task) }
      it "should create a BvaDispatchTask assigned to a User with a parent task assigned to the BvaDispatch org" do
        task = BvaDispatchTask.create_and_assign(root_task)
        expect(task.assigned_to.class).to eq(User)
        expect(task.parent.assigned_to.class).to eq(BvaDispatch)
      end
    end
  end

  describe ".outcode" do
    let(:user) { FactoryBot.create(:user) }
    let(:root_task) { FactoryBot.create(:root_task) }
    before { allow(BvaDispatchTask).to receive(:list_of_assignees).and_return([user.css_id]) }

    context "when single BvaDispatchTask exists for user and appeal combination" do
      before { BvaDispatchTask.create_and_assign(root_task) }

      it "should complete the BvaDispatchTask assigned to the User and the task assigned to the BvaDispatch org" do
        BvaDispatchTask.outcode(root_task.appeal, user)
        tasks = BvaDispatchTask.where(appeal: root_task.appeal, assigned_to: user)
        expect(tasks.length).to eq(1)
        task = tasks[0]
        expect(task.status).to eq("completed")
        expect(task.parent.status).to eq("completed")
      end
    end

    context "when multiple BvaDispatchTasks exists for user and appeal combination" do
      let(:task_count) { 4 }
      before { task_count.times { BvaDispatchTask.create_and_assign(root_task) } }

      it "should throw an error" do
        expect { BvaDispatchTask.outcode(root_task.appeal, user) }.to(raise_error) do |e|
          expect(e.class).to eq(Caseflow::Error::BvaDispatchTaskCountMismatch)
          expect(e.tasks.count).to eq(task_count)
          expect(e.user_id).to eq(user.id)
          expect(e.appeal_id).to eq(root_task.appeal.id)
        end
      end
    end

    context "when no BvaDispatchTasks exists for user and appeal combination" do
      it "should throw an error" do
        expect { BvaDispatchTask.outcode(root_task.appeal, user) }.to(raise_error) do |e|
          expect(e.class).to eq(Caseflow::Error::BvaDispatchTaskCountMismatch)
          expect(e.tasks.count).to eq(0)
          expect(e.user_id).to eq(user.id)
          expect(e.appeal_id).to eq(root_task.appeal.id)
        end
      end
    end
  end
end
