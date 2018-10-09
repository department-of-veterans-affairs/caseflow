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
    let(:citation_number) { "A18123456" }
    let(:params) do
      { appeal_id: root_task.appeal.external_id,
        citation_number: citation_number,
        decision_date: Date.new(1989, 12, 13).to_s,
        redacted_document_location: "C://Windows/User/BLOBLAW/Documents/Decision.docx" }
    end
    before { allow(BvaDispatchTask).to receive(:list_of_assignees).and_return([user.css_id]) }

    context "when single BvaDispatchTask exists for user and appeal combination" do
      before { BvaDispatchTask.create_and_assign(root_task) }

      it "should complete the BvaDispatchTask assigned to the User and the task assigned to the BvaDispatch org" do
        BvaDispatchTask.outcode(root_task.appeal, params, user)
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
        expect { BvaDispatchTask.outcode(root_task.appeal, params, user) }.to(raise_error) do |e|
          expect(e.class).to eq(Caseflow::Error::BvaDispatchTaskCountMismatch)
          expect(e.tasks.count).to eq(task_count)
          expect(e.user_id).to eq(user.id)
          expect(e.appeal_id).to eq(root_task.appeal.id)
        end
      end
    end

    context "when no BvaDispatchTasks exists for user and appeal combination" do
      it "should throw an error" do
        expect { BvaDispatchTask.outcode(root_task.appeal, params, user) }.to(raise_error) do |e|
          expect(e.class).to eq(Caseflow::Error::BvaDispatchTaskCountMismatch)
          expect(e.tasks.count).to eq(0)
          expect(e.user_id).to eq(user.id)
          expect(e.appeal_id).to eq(root_task.appeal.id)
        end
      end
    end

    context "when parameters do not pass vaidation" do
      let(:citation_number) { "ABADCITATIONUMBER" }
      before { BvaDispatchTask.create_and_assign(root_task) }

      it "should throw an error" do
        expect { BvaDispatchTask.outcode(root_task.appeal, params, user) }.to(raise_error) do |e|
          expect(e.class).to eq(Caseflow::Error::OutcodeValidationFailure)
        end
      end
    end

    context "when parameters do not include all required keys" do
      let(:incomplete_params) do
        p = params.clone
        p.delete(:decision_date)
        p
      end
      before { BvaDispatchTask.create_and_assign(root_task) }

      it "should complete the BvaDispatchTask assigned to the User and the task assigned to the BvaDispatch org" do
        expect { BvaDispatchTask.outcode(root_task.appeal, incomplete_params, user) }.to(raise_error) do |e|
          expect(e.class).to eq(ActiveRecord::NotNullViolation)
        end
      end
    end

    context "when task has already been outcoded" do
      let(:repeat_params) do
        p = params.clone
        p[:citation_number] = "A12131989"
        p
      end
      before do
        BvaDispatchTask.create_and_assign(root_task)
        BvaDispatchTask.outcode(root_task.appeal, params, user)
      end

      it "should raise an error" do
        expect { BvaDispatchTask.outcode(root_task.appeal, repeat_params, user) }.to(raise_error) do |e|
          expect(e.class).to eq(Caseflow::Error::BvaDispatchDoubleOutcode)
        end
      end
    end
  end
end
