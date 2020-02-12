# frozen_string_literal: true

describe LegacyWorkQueue, :all_dbs do
  context ".tasks_for_user" do
    let!(:user) { create(:user) }
    let!(:staff_record) { create(:staff, role, sdomainid: user.css_id) }
    let!(:appeals) do
      [
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user)),
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user))
      ]
    end

    subject { LegacyWorkQueue.tasks_for_user(user) }

    context "when it is an attorney" do
      let(:role) { :attorney_role }

      it "returns tasks" do
        expect(subject.length).to eq(2)
        expect(subject[0].class).to eq(AttorneyLegacyTask)
      end
    end

    context "when it is a judge" do
      let(:role) { :judge_role }

      it "returns tasks" do
        expect(subject.length).to eq(2)
        expect(subject[0].class).to eq(JudgeLegacyDecisionReviewTask)
      end
    end
  end

  context ".tasks_by_appeal_id" do
    let(:user) { User.find_or_create_by(css_id: "DNYGLVR", station_id: "LANCASTER") }

    let!(:appeals) do
      [
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user)),
        create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user))
      ]
    end
    let!(:appeal) { appeals[0] }

    before do
      create(:staff, role)
    end

    subject { LegacyWorkQueue.tasks_by_appeal_id(appeal.vacols_id) }

    context "when the user is an attorney" do
      let(:role) { :attorney_role }

      it "returns a task" do
        expect(subject.length).to eq(1)
        expect(subject[0].class).to eq(AttorneyLegacyTask)
      end
    end
  end

  context ".tasks_by_appeal_id: appeal assigned to a location" do
    let!(:location) { create(:staff, slogid: "38", sdomainid: nil) }

    let!(:appeals) do
      [
        create(:legacy_appeal, vacols_case: create(:case, bfcurloc: location.slogid)),
        create(:legacy_appeal, vacols_case: create(:case, bfcurloc: location.slogid))
      ]
    end
    let!(:appeal) { appeals[0] }

    subject { LegacyWorkQueue.tasks_by_appeal_id(appeal.vacols_id) }

    it "returns a task and an appeal" do
      tasks = subject
      expect(tasks.length).to eq(1)
      task = tasks[0]
      expect(task.class).to eq(AttorneyLegacyTask)
      expect(task.user_id).to be_nil
      expect(task.assigned_to_pg_id).to be_nil
    end
  end
end
