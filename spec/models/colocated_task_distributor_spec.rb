describe ColocatedTaskDistributor do
  let(:assignee_pool_size) { 6 }
  let(:colocated_org) { Colocated.singleton }
  let(:colocated_task_distributor) { ColocatedTaskDistributor.new }

  before do
    FactoryBot.create_list(:user, assignee_pool_size).each do |u|
      OrganizationsUser.add_user_to_organization(u, colocated_org)
    end
  end

  describe ".latest_task" do
    # Pick a random user from the list of assignees
    let(:assignee_index) { rand(colocated_org.users.length) }
    let(:assignee) { colocated_org.users[assignee_index] }

    context "when no tasks of type have been created" do
      it "should return nil" do
        expect(colocated_task_distributor.latest_task).to eq(nil)
      end
    end

    context "when a task has been assigned to a member of the list of assignees" do
      let!(:task) { FactoryBot.create(:task, assigned_to: assignee) }

      it "should return the most recent task" do
        expect(colocated_task_distributor.latest_task.id).to eq(task.id)
      end
    end

    context "when task assigned to Organization is most recent task" do
      let!(:user_task) { FactoryBot.create(:task, assigned_to: assignee) }
      let!(:org_task) { FactoryBot.create(:task, assigned_to: FactoryBot.create(:organization)) }

      it "should return the most recent task assigned to a User" do
        expect(colocated_task_distributor.latest_task.id).to eq(user_task.id)
      end
    end
  end

  describe ".next_assignee" do
    context "when there are no members of the Colocated team" do
      before do
        OrganizationsUser.where(organization: colocated_org).delete_all
      end

      it "should raise an error" do
        expect { colocated_task_distributor.next_assignee }.to(raise_error) do |error|
          expect(error).to be_a(Caseflow::Error::RoundRobinTaskDistributorError)
          expect(error.message).to eq("list_of_assignees cannot be empty")
        end
      end
    end

    context "when the list_of_assignees is a populated array" do
      let(:iterations) { 6 }
      let(:total_distribution_count) { iterations * assignee_pool_size }

      before do
        total_distribution_count.times do
          FactoryBot.create(:task, assigned_to: colocated_task_distributor.next_assignee)
        end
      end

      it "should have evenly distributed tasks to each assignee" do
        colocated_org.users.each do |user|
          expect(Task.where(assigned_to: user).count).to eq(iterations)
        end
      end
    end
  end
end
