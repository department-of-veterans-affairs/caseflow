describe AttorneyQueue do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context "#tasks" do
    let(:user) { create(:user) }
    let!(:staff) { create(:staff, :attorney_role, sdomainid: user.css_id) }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

    let!(:action1) { create(:colocated_admin_action, assigned_by: user) }
    let!(:action2) { create(:colocated_admin_action, appeal: appeal, assigned_by: user) }
    let!(:action3) { create(:colocated_admin_action, appeal: appeal, assigned_by: user, status: "completed") }

    subject { AttorneyQueue.new(user: user).tasks }

    context "when colocated admin actions are on hold" do
      it "should return the list" do
        # action2 and action3 belong to the same appeal so return both of them because one
        # admin action is not completed yet
        expect(subject.size).to eq 3
        expect(subject.first.status).to eq "on_hold"
        expect(subject.second.status).to eq "on_hold"
        expect(subject.third.status).to eq "on_hold"
      end
    end
  end
end
