describe ColocatedTaskDistributor do
  let(:assignee_pool_size) { 6 }
  let(:colocated_org) { Colocated.singleton }
  let(:colocated_task_distributor) { ColocatedTaskDistributor.new }

  before do
    FactoryBot.create_list(:user, assignee_pool_size).each do |u|
      OrganizationsUser.add_user_to_organization(u, colocated_org)
    end
  end

  describe ".next_assignee" do
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
