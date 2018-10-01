describe GenericTask do
  describe ".verify_user_access" do
    let(:user) { FactoryBot.create(:user) }
    let(:other_user) { FactoryBot.create(:user) }

    let(:org) { FactoryBot.create(:organization) }
    let(:field) { "sdept" }
    let(:fld_val) { org.name }
    let!(:sfo) { StaffFieldForOrganization.create!(organization: org, name: field, values: [fld_val]) }

    let(:other_org) { FactoryBot.create(:organization) }
    let!(:other_sfo) do
      StaffFieldForOrganization.create!(organization: other_org, name: field, values: [other_org.name])
    end

    let(:task) do
      t = FactoryBot.create(:generic_task, :in_progress, assigned_to: assignee)
      GenericTask.find(t.id)
    end

    before do
      FactoryBot.create(:staff, user: user, "#{field}": fld_val)
      FeatureToggle.enable!(org.feature.to_sym, users: [user.css_id])
    end

    context "task assignee is current user" do
      let(:assignee) { user }
      it "should not raise an error" do
        expect { task.verify_user_access(user) }.to_not raise_error
      end
    end

    context "task assignee is organization to which current user belongs" do
      let(:assignee) { org }
      it "should not raise an error" do
        expect { task.verify_user_access(user) }.to_not raise_error
      end
    end

    context "task assignee is a different person" do
      let(:assignee) { other_user }
      it "should raise an error" do
        expect { task.verify_user_access(user) }.to raise_error(Caseflow::Error::ActionForbiddenError)
      end
    end

    context "task assignee is organization to which current user does not belong" do
      let(:assignee) { other_org }
      it "should raise an error" do
        expect { task.verify_user_access(user) }.to raise_error(Caseflow::Error::ActionForbiddenError)
      end
    end
  end

  describe ".update_from_params" do
    let(:user) { FactoryBot.create(:user) }
    let(:org) { FactoryBot.create(:organization) }
    let(:field) { "sdept" }
    let(:fld_val) { org.name }
    let!(:sfo) { StaffFieldForOrganization.create!(organization: org, name: field, values: [fld_val]) }
    let(:task) do
      t = FactoryBot.create(:generic_task, :in_progress, assigned_to: assignee)
      GenericTask.find(t.id)
    end

    context "task is assigned to an organization" do
      let(:assignee) { org }

      context "and current user does not belong to that organization" do
        it "should raise an error when trying to call Task.mark_as_complete!" do
          expect { task.update_from_params({}, user) }.to raise_error(Caseflow::Error::ActionForbiddenError)
        end
      end

      context "and current user belongs to that organization" do
        before do
          FactoryBot.create(:staff, user: user, "#{field}": fld_val)
          FeatureToggle.enable!(org.feature.to_sym, users: [user.css_id])
        end

        it "should call Task.mark_as_complete!" do
          expect_any_instance_of(GenericTask).to receive(:mark_as_complete!)
          task.update_from_params({}, user)
        end
      end
    end

    context "task is assigned to a person" do
      let(:other_user) { FactoryBot.create(:user) }
      let(:assignee) { user }

      context "who is not the current user" do
        it "should raise an error when trying to call Task.mark_as_complete!" do
          expect { task.update_from_params({}, other_user) }.to raise_error(Caseflow::Error::ActionForbiddenError)
        end
      end

      context "who is the current user" do
        it "should call Task.mark_as_complete!" do
          expect_any_instance_of(GenericTask).to receive(:mark_as_complete!)
          task.update_from_params({}, user)
        end
      end
    end
  end

  describe ".create_from_params" do
    let(:parent_assignee) { FactoryBot.create(:user) }
    let(:current_user) { FactoryBot.create(:user) }
    let(:assignee) { FactoryBot.create(:user) }
    let(:parent) do
      t = FactoryBot.create(:generic_task, :in_progress, assigned_to: parent_assignee)
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
        expect { GenericTask.create_from_params(params, parent_assignee) }.to raise_error(TypeError)
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
        expect { GenericTask.create_from_params(params, parent_assignee) }.to raise_error(ActiveRecord::RecordNotFound)
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
        GenericTask.create_from_params(params, parent_assignee)
        expect(GenericTask.where(params).count).to eq(1)
        expect(parent.status).to eq(status_before)
      end
    end

    context "when all parameters present" do
      it "should create child task and update parent task's status" do
        status_before = parent.status
        GenericTask.create_from_params(good_params, parent_assignee)
        expect(GenericTask.where(good_params.except(:status)).count).to eq(1)
        expect(parent.reload.status).to_not eq(status_before)
        expect(parent.status).to eq(good_params[:status])
      end
    end

    context "when parent task is assigned to a user" do
      context "when there is no current user" do
        it "should raise error and not create the child task nor update status" do
          expect { GenericTask.create_from_params(good_params, nil) }.to(
            raise_error(Caseflow::Error::ActionForbiddenError)
          )
        end
      end

      context "when the currently logged-in user owns the parent task" do
        let(:parent_assignee) { current_user }
        it "should create child task assigned by currently logged-in user" do
          child = GenericTask.create_from_params(good_params, current_user)
          expect(child.assigned_by_id).to eq(current_user.id)
        end
      end
    end

    context "when parent task is assigned to an organization" do
      let(:org) { FactoryBot.create(:organization) }
      let(:field) { "sdept" }
      let(:fld_val) { org.name }
      let!(:sfo) { StaffFieldForOrganization.create!(organization: org, name: field, values: [fld_val]) }
      let(:parent) do
        t = FactoryBot.create(:generic_task, :in_progress, assigned_to: org)
        GenericTask.find(t.id)
      end

      context "when there is no current user" do
        it "should raise error and not create the child task nor update status" do
          expect { GenericTask.create_from_params(good_params, nil) }.to(
            raise_error(Caseflow::Error::ActionForbiddenError)
          )
        end
      end

      context "when there is a currently logged-in user" do
        before do
          FactoryBot.create(:staff, user: current_user, "#{field}": fld_val)
          FeatureToggle.enable!(org.feature.to_sym, users: [current_user.css_id])
        end
        it "should create child task assigned by currently logged-in user" do
          child = GenericTask.create_from_params(good_params, current_user)
          expect(child.assigned_by_id).to eq(current_user.id)
        end
      end
    end
  end
end
