# frozen_string_literal: true

describe DasDeprecation::CaseDistribution, :all_dbs do
  let(:judge) { create(:user, css_id: "BVATWARNER", roles: ["Hearing Prep"]) }
  describe "#create_judge_assign_task" do
    context "Non-Priority Legacy Appeal" do
      let!(:legacy_priority_cases) do
        create(:case,
               bfd19: 1.year.ago,
               bfac: "1",
               bfmpro: "ACT",
               bfcurloc: "81",
               bfdloout: 1.day.ago,
               folder: build(:folder, tinum: "1801010", titrnum: "123456789S"))
      end

      let(:record) do
        LegacyAppeal.repository.distribute_nonpriority_appeals(judge, "any", nil, 1, false).first
      end

      it "record is not nil" do
        expect(record).not_to be_nil
      end

      it "appeal is created if it does not exist" do
        DasDeprecation::CaseDistribution.create_judge_assign_task(record, judge)
        legacy_appeal = LegacyAppeal.find_by(vacols_id: record["bfkey"])
        expect(legacy_appeal).not_to be_nil
      end

      it "assigns task to the judge" do
        DasDeprecation::CaseDistribution.create_judge_assign_task(record, judge)
        legacy_appeal = LegacyAppeal.find_by(vacols_id: record["bfkey"])
        expect(legacy_appeal.tasks.of_type(:JudgeAssignTask).first.assigned_to)
          .to eq(judge)
      end

      it "appeal type on task is LegacyAppeal" do
        DasDeprecation::CaseDistribution.create_judge_assign_task(record, judge)
        task = JudgeAssignTask.find_by(assigned_to: judge)
        expect(task.appeal_type).to eq("LegacyAppeal")
      end

      it "JudgeAssignTask is a child of RootTask" do
        DasDeprecation::CaseDistribution.create_judge_assign_task(record, judge)
        task = JudgeAssignTask.find_by(assigned_to: judge)
        expect(task.parent.type).to eq("RootTask")
      end
    end
  end
end
