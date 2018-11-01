describe AttorneyQueue do
  context "#tasks" do
    let(:user) { create(:user) }
    let!(:staff) { create(:staff, :attorney_role, sdomainid: user.css_id) }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

    let!(:action1) { create(:colocated_task, assigned_by: user) }
    let!(:action2) { create(:colocated_task, appeal: appeal, assigned_by: user) }
    let!(:action3) { create(:colocated_task, appeal: appeal, assigned_by: user, status: "completed") }
    let!(:action4) { create(:colocated_task, assigned_by: user, status: "completed") }
    let!(:action5) { create(:colocated_task, assigned_by: user, status: "in_progress") }

    subject { AttorneyQueue.new(user: user).tasks }

    context "when colocated admin actions are on hold" do
      it "should return the list" do
        # action2 and action3 belong to the same appeal so return both of them because one
        # admin action is not completed yet
        expect(subject.size).to eq 4
        expect(subject[0].status).to eq "on_hold"
        expect(subject[1].status).to eq "on_hold"
        expect(subject[2].status).to eq "on_hold"
        expect(subject[3].status).to eq "on_hold"
      end
    end
  end
end
