describe BvaDispatchTask do
  describe ".create_and_assign" do
    context "when no root_task passed as argument" do
      it "throws an error" do
        expect { BvaDispatchTask.create_and_assign(nil) }.to raise_error(NoMethodError)
      end
    end

    context "when valid root_task passed as argument" do
      let(:root_task) { FactoryBot.create(:root_task) }
      before do
        # Make sure the BvaDispatch team has members
        OrganizationsUser.add_user_to_organization(FactoryBot.create(:user), BvaDispatch.singleton)
      end

      it "should create a BvaDispatchTask assigned to a User with a parent task assigned to the BvaDispatch org" do
        task = BvaDispatchTask.create_and_assign(root_task)
        expect(task.assigned_to.class).to eq(User)
        expect(task.parent.assigned_to.class).to eq(BvaDispatch)
        expect(task.parent.status).to eq(Constants.TASK_STATUSES.on_hold)
      end
    end

    context "when organization-level BvaDispatchTask already exists" do
      let(:root_task) { FactoryBot.create(:root_task) }
      before do
        # Make sure the BvaDispatch team has members
        OrganizationsUser.add_user_to_organization(FactoryBot.create(:user), BvaDispatch.singleton)
        BvaDispatchTask.create_and_assign(root_task)
      end

      it "should raise an error" do
        expect { BvaDispatchTask.create_and_assign(root_task) }.to raise_error(Caseflow::Error::DuplicateOrgTask)
      end
    end
  end

  describe ".outcode" do
    let(:user) { FactoryBot.create(:user) }
    let(:root_task) { FactoryBot.create(:root_task) }
    let(:citation_number) { "A18123456" }
    let(:file) { "JVBERi0xLjMNCiXi48/TDQoNCjEgMCBvYmoNCjw8DQovVHlwZSAvQ2F0YW" }
    let(:params) do
      { appeal_id: root_task.appeal.external_id,
        citation_number: citation_number,
        decision_date: Date.new(1989, 12, 13).to_s,
        file: file,
        redacted_document_location: "C://Windows/User/BLOBLAW/Documents/Decision.docx" }
    end
    before do
      allow(BvaDispatchTask).to receive(:list_of_assignees).and_return([user.css_id])
    end

    context "when single BvaDispatchTask exists for user and appeal combination" do
      before { BvaDispatchTask.create_and_assign(root_task) }

      it "should complete the BvaDispatchTask assigned to the User and the task assigned to the BvaDispatch org" do
        expect(Caseflow::Fakes::S3Service).to receive(:store_file)
          .with("decisions/" + root_task.appeal.external_id + ".pdf", /decisions/, :filepath)
        allow(VBMSService).to receive(:upload_document_to_vbms)
        BvaDispatchTask.outcode(root_task.appeal, params, user)
        tasks = BvaDispatchTask.where(appeal: root_task.appeal, assigned_to: user)
        expect(tasks.length).to eq(1)
        task = tasks[0]
        expect(task.status).to eq("completed")
        expect(task.parent.status).to eq("completed")
        expect(task.root_task.status).to eq("completed")
        decision = Decision.find_by(appeal_id: root_task.appeal.id)
        expect(decision).to_not eq nil
        expect(VBMSService).to have_received(:upload_document_to_vbms).with(root_task.appeal, decision)
        expect(decision.document_type).to eq "BVA Decision"
        expect(decision.source).to eq "BVA"
      end
    end

    context "when multiple BvaDispatchTasks exists for user and appeal combination" do
      let(:task_count) { 4 }
      before do
        task_count.times do
          personal_task = BvaDispatchTask.create_and_assign(root_task)
          # Set status of org-level task to completed to avoid getting caught by GenericTask.verify_org_task_unique.
          personal_task.parent.update!(status: Constants.TASK_STATUSES.completed)
        end
      end

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
        allow(Caseflow::Fakes::S3Service).to receive(:store_file)
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
