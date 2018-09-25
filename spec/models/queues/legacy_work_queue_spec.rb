describe LegacyWorkQueue do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context ".tasks_with_appeals" do
    let(:user) { User.find_or_create_by(css_id: "DNYGLVR", station_id: "LANCASTER") }

    let!(:appeals) do
      [
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user)),
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user))
      ]
    end

    let!(:decass) do
      [
        create(:decass, defolder: appeals[0].vacols_id, dereceive: Date.new(2018, 9, 24), deprod: "DEC"),
        create(:decass, defolder: appeals[1].vacols_id, dereceive: Date.new(2018, 9, 24), deprod: "REA")
      ]
    end

    context "when it is an attorney" do
      let(:role) { "Attorney" }

      it "returns tasks" do
        tasks, = LegacyWorkQueue.tasks_with_appeals(user, role)

        expect(tasks.length).to eq(2)
        expect(tasks[0].class).to eq(AttorneyLegacyTask)
      end

      it "returns appeals" do
        _, appeals = LegacyWorkQueue.tasks_with_appeals(user, role)

        expect(appeals.length).to eq(2)
        expect(appeals[0].class).to eq(LegacyAppeal)
      end
    end

    context "when it is a judge" do
      let(:role) { "Judge" }

      it "returns tasks" do
        tasks, = LegacyWorkQueue.tasks_with_appeals(user, role)

        expect(tasks.length).to eq(2)
        if tasks[0].action == "assign"
          assign, review = tasks
        else
          review, assign = tasks
        end
        expect(assign.class).to eq(JudgeLegacyTask)
        expect(assign.action).to eq("assign")
        expect(review.action).to eq("review")
      end

      it "returns appeals" do
        _, appeals = LegacyWorkQueue.tasks_with_appeals(user, role)

        expect(appeals.length).to eq(2)
        expect(appeals[0].class).to eq(LegacyAppeal)
      end
    end
  end

  context ".tasks_with_appeals_by_appeal_id" do
    let(:user) { User.find_or_create_by(css_id: "DNYGLVR", station_id: "LANCASTER") }

    let!(:appeals) do
      [
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user)),
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user))
      ]
    end
    let!(:appeal) { appeals[0] }

    context "when the user is an attorney" do
      let(:role) { "attorney" }

      it "returns a task" do
        tasks, = LegacyWorkQueue.tasks_with_appeals_by_appeal_id(appeal.vacols_id, role)

        expect(tasks.length).to eq(1)
        expect(tasks[0].class).to eq(AttorneyLegacyTask)
      end

      it "returns an appeal" do
        _, appeals = LegacyWorkQueue.tasks_with_appeals_by_appeal_id(appeal.vacols_id, role)

        expect(appeals.length).to eq(1)
        expect(appeals[0].class).to eq(LegacyAppeal)
      end
    end
  end

  context ".tasks_with_appeals_by_appeal_id: appeal assigned to a location" do
    let!(:location) { create(:staff, slogid: "38", sdomainid: nil) }

    let!(:appeals) do
      [
        create(:legacy_appeal, vacols_case: create(:case, bfcurloc: location.slogid)),
        create(:legacy_appeal, vacols_case: create(:case, bfcurloc: location.slogid))
      ]
    end
    let!(:appeal) { appeals[0] }

    context "when the user is an attorney" do
      let(:role) { "attorney" }

      it "returns a task and an appeal" do
        tasks, appeals = LegacyWorkQueue.tasks_with_appeals_by_appeal_id(appeal.vacols_id, role)

        expect(tasks.length).to eq(1)
        task = tasks[0]
        expect(task.class).to eq(AttorneyLegacyTask)
        expect(task.user_id).to be_nil
        expect(task.assigned_to_pg_id).to be_nil
        expect(appeals.length).to eq(1)
        expect(appeals[0].class).to eq(LegacyAppeal)
      end
    end
  end
end
