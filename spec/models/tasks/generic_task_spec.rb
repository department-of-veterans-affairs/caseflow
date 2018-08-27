describe GenericTask do
  describe ".update_from_params" do
    let(:task) do
      t = FactoryBot.create(:generic_task, :in_progress)
      GenericTask.find(t.id)
    end
    it "should call Task.mark_as_complete!" do
      expect_any_instance_of(GenericTask).to receive(:mark_as_complete!)
      task.update_from_params({})
    end
  end

  describe ".create_from_params" do
    let(:assignee) { FactoryBot.create(:user) }
    let(:parent) do
      t = FactoryBot.create(:generic_task, :in_progress)
      GenericTask.find(t.id)
    end
    let(:good_params) do
      {
        status: "completed",
        parent_id: parent.id,
        assigned_to_type: assignee.class.name,
        assigned_to_id: assignee.id
      }
    end

    context "when missing assignee parameter" do
      let(:params) do
        {
          status: good_params[:status],
          parent_id: good_params[:parent_id],
          assigned_to_id: good_params[:assigned_to_id]
        }
      end
      it "should raise error before not creating child task nor update status" do
        expect { GenericTask.create_from_params(params) }.to raise_error(TypeError)
      end
    end

    context "when missing parent_id parameter" do
      let(:params) do
        {
          status: good_params[:status],
          assigned_to_type: good_params[:assigned_to_type],
          assigned_to_id: good_params[:assigned_to_id]
        }
      end
      it "should raise error before not creating child task nor update status" do
        expect { GenericTask.create_from_params(params) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when missing status parameter" do
      let(:params) do
        {
          parent_id: good_params[:parent_id],
          assigned_to_type: good_params[:assigned_to_type],
          assigned_to_id: good_params[:assigned_to_id]
        }
      end
      it "should create child task and not update parent task's status" do
        status_before = parent.status
        GenericTask.create_from_params(params)
        expect(GenericTask.where(params).count).to eq(1)
        expect(parent.status).to eq(status_before)
      end
    end

    context "when all parameters present" do
      it "should create child task and update parent task's status" do
        status_before = parent.status
        GenericTask.create_from_params(good_params)
        expect(GenericTask.where(good_params.except(:status)).count).to eq(1)
        expect(parent.reload.status).to_not eq(status_before)
        expect(parent.status).to eq(good_params[:status])
      end
    end
  end
end
