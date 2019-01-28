describe AttorneyQueue do
  context "#tasks" do
    let(:user) { create(:user) }
    let!(:staff) { create(:staff, :attorney_role, sdomainid: user.css_id) }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

    subject { AttorneyQueue.new(user: user).tasks }

    context "when colocated admin actions are on hold" do
      let!(:action1) { create(:colocated_task, assigned_by: user) }
      let!(:action2) { create(:colocated_task, appeal: appeal, assigned_by: user) }
      let!(:action3) { create(:colocated_task, appeal: appeal, assigned_by: user, status: "completed") }
      let!(:action4) { create(:colocated_task, assigned_by: user, status: "completed") }
      let!(:action5) { create(:colocated_task, assigned_by: user, status: "in_progress") }

      it "should return the list" do
        expect(subject.size).to eq 3
        expect(subject[0].status).to eq "on_hold"
        expect(subject[1].status).to eq "on_hold"
        expect(subject[2].status).to eq "on_hold"
      end
    end

    context "when complete and incomplete colocated admin actions exist for an appeal" do
      let!(:completed_action) do
        FactoryBot.create(:colocated_task, :completed, appeal: appeal, assigned_by: user)
      end
      let!(:incomplete_action) do
        FactoryBot.create(:colocated_task, :on_hold, appeal: appeal, assigned_by: user).becomes(ColocatedTask)
      end

      it "should only return the incomplete colocated admin actions" do
        expect(subject.size).to eq(1)
        expect(subject.first).to eq(incomplete_action)
      end
    end
  end
end
