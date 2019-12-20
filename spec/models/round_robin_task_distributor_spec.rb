# frozen_string_literal: true

describe RoundRobinTaskDistributor, :all_dbs do
  let(:assignee_pool_size) { 6 }
  let!(:assignee_pool) { create_list(:user, assignee_pool_size) }
  let(:task_class) { Task }
  let(:round_robin_distributor) do
    RoundRobinTaskDistributor.new(assignee_pool: assignee_pool, task_class: task_class)
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
      let!(:previous_tasks) { create_list(:task, 8) }
      let!(:task) { create(:task, assigned_to: assignee) }

      it "should return the most recent task" do
        expect(round_robin_distributor.latest_task.id).to eq(task.id)
      end
    end

    context "when task assigned to Organization is most recent task" do
      before do
        create(:task, assigned_to: assignee)
        create(:task, assigned_to: create(:organization))
      end

      it "should return the most recent task assigned to a User" do
        expect(round_robin_distributor.latest_task.assigned_to_type).to eq(User.name)
        expect(Task.all.max_by(&:created_at).assigned_to_type).to eq(Organization.name)
      end
    end
  end

  describe ".next_assignee" do
    context "the distributor is invalid" do
      context "the assignee_pool is empty" do
        let!(:assignee_pool) { [] }

        it "raises an error" do
          expect { round_robin_distributor.next_assignee }.to(raise_error) do |error|
            expect(error).to be_a(Caseflow::Error::RoundRobinTaskDistributorError)
            expect(error.message).to eq("Assignee pool can't be blank")
          end
        end
      end

      context "the task_class is blank" do
        let(:task_class) { nil }

        it "raises an error" do
          expect { round_robin_distributor.next_assignee }.to(raise_error) do |error|
            expect(error).to be_a(Caseflow::Error::RoundRobinTaskDistributorError)
            expect(error.message).to eq("Task class can't be blank")
          end
        end
      end

      context "the assignee_pool contains items that aren't Users" do
        let!(:assignee_pool) { create_list(:organization, assignee_pool_size) }

        it "raises an error" do
          expect { round_robin_distributor.next_assignee }.to(raise_error) do |error|
            expect(error).to be_a(Caseflow::Error::RoundRobinTaskDistributorError)
            expect(error.message).to eq("Assignee pool #{COPY::TASK_DISTRIBUTOR_ASSIGNEE_POOL_USERS_ONLY_MESSAGE}")
          end
        end
      end
    end

    context "the assignee_pool is a populated array" do
      let(:iterations) { 4 }
      let(:total_distribution_count) { iterations * assignee_pool_size }

      before do
        total_distribution_count.times do
          create(:task, assigned_to: round_robin_distributor.next_assignee)
        end
      end

      it "should have evenly distributed tasks to each assignee" do
        assignee_pool.each do |user|
          expect(Task.where(assigned_to: user).count).to eq(iterations)
        end
      end
    end

    context "the assignee_pool has inactive users" do
      let(:iterations) { 4 }
      let(:total_distribution_count) { iterations * assignee_pool_size }
      let(:number_of_inactive_users) { assignee_pool_size / 2 }

      before do
        assignee_pool.take(number_of_inactive_users).each(&:inactive!)
        total_distribution_count.times do
          create(:task, assigned_to: round_robin_distributor.next_assignee)
        end
      end

      it "should have evenly distributed tasks to each assignee" do
        assignee_pool.select(&:active?).each do |user|
          expect(Task.where(assigned_to: user).count).to eq(iterations * 2)
        end
        assignee_pool.select(&:inactive?).each do |user|
          expect(Task.where(assigned_to: user).count).to eq(0)
        end
      end
    end
  end
end
