describe CoLocatedAdminAction do
  let(:attorney) { User.create(css_id: "CFS456", station_id: User::BOARD_STATION_ID) }
  let(:appeal) { LegacyAppeal.create(vacols_id: "123456") }

  before do
    allow_any_instance_of(User).to receive(:vacols_role).and_return("Attorney")
  end

  context ".create" do
    context "when all fields are present" do
      subject do
        CoLocatedAdminAction.create(
          assigned_by: attorney,
          title: :aoj,
          appeal: appeal
        )
      end
      it "creates a co-located task successfully" do
        expect(subject.valid?).to be true
        expect(subject.status).to eq "assigned"
        expect(subject.assigned_at).to be DateTime
        expect(subject.assigned_by).to eq attorney
        expect(subject.assigned_to).to eq User.find_by(css_id: "BVATEST1")
      end
    end
  end
end