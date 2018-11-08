describe LegacyWorkQueue do
  context ".tasks_with_appeals" do
    let(:user) { User.find_or_create_by(css_id: "DNYGLVR", station_id: "LANCASTER") }

    let!(:appeals) do
      [
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user)),
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user))
      ]
    end

    subject { LegacyWorkQueue.tasks_with_appeals(user, role) }

    context "when it is an attorney" do
      let(:role) { "Attorney" }

      it "returns tasks" do
        expect(subject[0].length).to eq(2)
        expect(subject[0][0].class).to eq(AttorneyLegacyTask)
      end

      it "returns appeals" do
        expect(subject[1].length).to eq(2)
        expect(subject[1][0].class).to eq(LegacyAppeal)
      end
    end

    context "when it is a judge" do
      let(:role) { "Judge" }

      it "returns tasks" do
        expect(subject[0].length).to eq(2)
        expect(subject[0][0].class).to eq(JudgeLegacyTask)
      end

      it "returns appeals" do
        expect(subject[1].length).to eq(2)
        expect(subject[1][0].class).to eq(LegacyAppeal)
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

    subject { LegacyWorkQueue.tasks_with_appeals_by_appeal_id(appeal.vacols_id, role) }

    context "when the user is an attorney" do
      let(:role) { "attorney" }

      it "returns a task" do
        expect(subject[0].length).to eq(1)
        expect(subject[0][0].class).to eq(AttorneyLegacyTask)
      end

      it "returns an appeal" do
        expect(subject[1].length).to eq(1)
        expect(subject[1][0].class).to eq(LegacyAppeal)
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

    subject { LegacyWorkQueue.tasks_with_appeals_by_appeal_id(appeal.vacols_id, role) }

    context "when the user is an attorney" do
      let(:role) { "attorney" }

      it "returns a task and an appeal" do
        tasks, appeals = subject
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
