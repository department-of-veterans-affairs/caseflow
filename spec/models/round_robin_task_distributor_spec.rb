describe RoundRobinTaskDistributor do
  let(:assignee_pool_size) { 6 }
  let!(:assignee_pool) { FactoryBot.create_list(:user, assignee_pool_size) }
  let(:task_class) { Task }
  let(:round_robin_distributor) do
    RoundRobinTaskDistributor.new(list_of_assignees: assignee_pool.pluck(:css_id), task_class: task_class)
  end

  describe ".latest_task" do
    # Pick a random user from the list of assignees
    let(:assignee_index) { rand(assignee_pool_size) }
    let(:assignee) { assignee_pool[assignee_index] }

    context "when no tasks of type have been created" do
      it "should return nil" do
        expect(round_robin_distributor.latest_task).to eq(nil)
      end
    end

    context "when a task has been assigned to a member of the list of assignees" do
      let!(:previous_tasks) { FactoryBot.create_list(:task, 8) }
      let!(:task) { FactoryBot.create(:task, assigned_to: assignee) }

      it "should return the most recent task" do
        expect(round_robin_distributor.latest_task.id).to eq(task.id)
      end
    end

    context "when task assigned to Organization is most recent task" do
      before do
        FactoryBot.create(:task, assigned_to: assignee)
        FactoryBot.create(:task, assigned_to: FactoryBot.create(:organization))
      end

      it "should return the most recent task assigned to a User" do
        expect(round_robin_distributor.latest_task.assigned_to_type).to eq(User.name)
        expect(Task.all.max_by(&:created_at).assigned_to_type).to eq(Organization.name)
      end
    end
  end

  describe ".next_assignee" do
    context "when the list_of_assignees is an empty array" do
      let(:round_robin_distributor) { RoundRobinTaskDistributor.new(list_of_assignees: [], task_class: task_class) }

      it "should raise an error" do
        expect { round_robin_distributor.next_assignee }.to(raise_error) do |error|
          expect(error).to be_a(Caseflow::Error::RoundRobinTaskDistributorError)
          expect(error.message).to eq("list_of_assignees cannot be empty")
        end
      end
    end

    context "when the list_of_assignees is a populated array" do
      let(:iterations) { 4 }
      let(:total_distribution_count) { iterations * assignee_pool_size }

      before do
        total_distribution_count.times do
          FactoryBot.create(:task, assigned_to: round_robin_distributor.next_assignee)
        end
      end

      it "should have evenly distributed tasks to each assignee" do
        assignee_pool.each do |user|
          expect(Task.where(assigned_to: user).count).to eq(iterations)
        end
      end
    end
  end
end
