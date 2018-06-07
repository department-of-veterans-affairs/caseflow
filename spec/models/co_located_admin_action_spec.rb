describe CoLocatedAdminAction do
  let(:attorney) { User.create(css_id: "CFS456", station_id: User::BOARD_STATION_ID) }
  let!(:vacols_case) { create(:case) }
  let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

  before do
    RequestStore.store[:current_user] = attorney
    allow_any_instance_of(User).to receive(:vacols_role).and_return("Attorney")
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
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
        expect(subject.assigned_at).to_not eq nil
        expect(subject.assigned_by).to eq attorney
        expect(subject.assigned_to).to eq User.find_by(css_id: "BVATEST1")
        expect(vacols_case.reload.bfcurloc).to eq "CASEFLOW"
      end
    end

    context "when appeal is missing" do
      subject do
        CoLocatedAdminAction.create(
          assigned_by: attorney,
          title: :aoj
        )
      end
      it "does not create a co-located task" do
        expect(subject.valid?).to be false
        expect(subject.errors.full_messages).to eq ["Appeal can't be blank"]
      end
    end

    context "when assigned by is not an attorney" do
      before do
        allow_any_instance_of(User).to receive(:vacols_role).and_return("Judge")
      end

      subject do
        CoLocatedAdminAction.create(
          assigned_by: attorney,
          title: :aoj,
          appeal: appeal
        )
      end
      it "does not create a co-located task" do
        expect(subject.valid?).to be false
        expect(subject.errors.full_messages).to eq ["Assigned by has to be an attorney"]
      end
    end

    context "when title is not valid" do
      subject do
        CoLocatedAdminAction.create(
          assigned_by: attorney,
          title: :test,
          appeal: appeal
        )
      end
      it "does not create a co-located task" do
        expect(subject.valid?).to be false
        expect(subject.errors.full_messages).to eq ["Title is not included in the list"]
      end
    end
  end
end
