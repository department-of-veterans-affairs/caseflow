# frozen_string_literal: true

describe ColocatedTaskDistributor, :all_dbs do
  let(:assignee_pool_size) { 6 }
  let(:colocated_org) { Colocated.singleton }
  let(:colocated_task_distributor) { ColocatedTaskDistributor.new }

  before do
    create_list(:user, assignee_pool_size).each do |u|
      colocated_org.add_user(u)
    end
  end

  describe ".next_assignee" do
    let(:iterations) { 6 }

    context "when the assignee_pool is a populated array" do
      let(:total_distribution_count) { iterations * assignee_pool_size }

      before do
        total_distribution_count.times do
          create(:task, assigned_to: colocated_task_distributor.next_assignee)
        end
      end

      it "should have evenly distributed tasks to each assignee" do
        colocated_org.users.each do |user|
          expect(Task.where(assigned_to: user).count).to eq(iterations)
        end
      end
    end

    context "when there are multiple tasks for the same appeal" do
      let(:appeal) { create(:appeal) }

      before do
        iterations.times do
          create(
            :task,
            appeal: appeal,
            assigned_to: colocated_task_distributor.next_assignee(appeal: appeal)
          )
        end
      end

      it "should assign all tasks to the same assignee" do
        expect(Task.all.map(&:assigned_to_id).uniq.count).to eq 1
      end
    end

    context "when a task is assigned to somebody else not in our list of assignees" do
      it "should not reset the next_assignee to the first member in our list of assignees" do
        # Create tasks assigned to all but one member of the list of assignees
        (assignee_pool_size - 1).times do
          create(:task, assigned_to: colocated_task_distributor.next_assignee)
        end

        last_assignee_index = assignee_pool_size - 1
        expect(colocated_task_distributor.next_assignee_index).to eq(last_assignee_index)

        # Create a task assigned to somebody not in the list of assignees
        create(:task)
        expect(colocated_task_distributor.next_assignee_index).to eq(last_assignee_index)
      end
    end
  end
end
