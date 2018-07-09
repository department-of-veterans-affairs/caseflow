describe CoLocatedAdminAction do
  let(:attorney) { User.create(css_id: "CFS456", station_id: User::BOARD_STATION_ID) }
  let!(:vacols_case) { create(:case) }
  let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

  before do
    RequestStore.store[:current_user] = attorney
    allow_any_instance_of(User).to receive(:vacols_roles).and_return(["attorney"])
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
          titles: [:aoj, :poa_clarification],
          appeal: appeal
        )
      end

      it "creates a co-located task successfully" do
        expect(subject.first.valid?).to be true
        expect(subject.first.status).to eq "assigned"
        expect(subject.first.assigned_at).to_not eq nil
        expect(subject.first.assigned_by).to eq attorney
        expect(subject.first.title).to eq "aoj"
        expect(subject.first.assigned_to).to eq User.find_by(css_id: "BVATEST1")

        expect(subject.second.valid?).to be true
        expect(subject.second.status).to eq "assigned"
        expect(subject.second.assigned_at).to_not eq nil
        expect(subject.second.assigned_by).to eq attorney
        expect(subject.second.title).to eq "poa_clarification"
        expect(subject.second.assigned_to).to eq User.find_by(css_id: "BVATEST1")

        expect(vacols_case.reload.bfcurloc).to eq "CASEFLOW"

        record = CoLocatedAdminAction.create(assigned_by: attorney, titles: [:aoj], appeal: appeal)
        expect(record.first.assigned_to).to eq User.find_by(css_id: "BVATEST2")

        record = CoLocatedAdminAction.create(assigned_by: attorney, titles: [:aoj], appeal: appeal)
        expect(record.first.assigned_to).to eq User.find_by(css_id: "BVATEST3")

        # should start from index 0
        record = CoLocatedAdminAction.create(assigned_by: attorney, titles: [:aoj], appeal: appeal)
        expect(record.first.assigned_to).to eq User.find_by(css_id: "BVATEST1")
      end
    end

    context "when appeal is missing" do
      subject do
        CoLocatedAdminAction.create(
          assigned_by: attorney,
          titles: [:aoj]
        )
      end
      it "does not create a co-located task" do
        expect(subject.first.valid?).to be false
        expect(subject.first.errors.full_messages).to eq ["Appeal can't be blank"]
      end
    end

    context "when assigned by is not an attorney" do
      before do
        allow_any_instance_of(User).to receive(:vacols_roles).and_return(["judge"])
      end

      subject do
        CoLocatedAdminAction.create(
          assigned_by: attorney,
          titles: [:aoj],
          appeal: appeal
        )
      end
      it "does not create a co-located task" do
        expect(subject.first.valid?).to be false
        expect(subject.first.errors.full_messages).to eq ["Assigned by has to be an attorney"]
      end
    end

    context "when title is not valid" do
      subject do
        CoLocatedAdminAction.create(
          assigned_by: attorney,
          titles: [:test],
          appeal: appeal
        )
      end
      it "does not create a co-located task" do
        expect(subject.first.valid?).to be false
        expect(subject.first.errors.full_messages).to eq ["Title is not included in the list"]
      end
    end
  end
end
