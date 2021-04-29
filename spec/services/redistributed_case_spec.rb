# frozen_string_literal: true

describe RedistributedCase, :all_dbs do
  let!(:vacols_case) { create(:case, bfcurloc: "CASEFLOW") }
  let(:judge) { create(:user) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }
  let(:distribution) { Distribution.create!(judge: judge) }
  # legacy_appeal.vacols_id is set to legacy_appeal.case_record["bfkey"]
  subject { RedistributedCase.new(case_id: legacy_appeal.vacols_id, new_distribution: distribution) }

  context ".allow!" do
    context "when legacy case does not exist" do
      subject { RedistributedCase.new(case_id: "does-not-exists", new_distribution: distribution) }
      it "reports case not found error" do
        error_msg = ""
        allow(Raven).to receive(:capture_exception) { |exc, _| error_msg = exc.message }

        subject.allow!
        expect(error_msg).to eq("Case not found")
      end
    end
  end

  context ".ok_to_redistribute?" do
    shared_examples "valid redistribution" do
      let(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
      it "returns true" do
        expect(subject.ok_to_redistribute?).to eq true
      end
    end
    context "when there are no relevant tasks" do
      include_examples "valid redistribution"
    end
    context "when tasks are an empty array" do
      before do
        legacy_appeal.tasks = []
      end
      include_examples "valid redistribution"
    end
    context "when RootTask and TrackVeteranTask exist" do
      before do
        # TrackVeteranTask should be ignored by ok_to_redistribute?
        TrackVeteranTask.create!(appeal: legacy_appeal, assigned_to: create(:vso))
      end
      context "when there is an open JudgeAssignTask (non-HearingTask)" do
        let(:legacy_appeal) { create(:legacy_appeal, :with_judge_assign_task, vacols_case: vacols_case) }

        it "returns false because of open task" do
          expect(subject.ok_to_redistribute?).to eq false
        end
      end
      context "when there is a completed JudgeAssignTask (non-HearingTask)" do
        let(:legacy_appeal) { create(:legacy_appeal, :with_judge_assign_task, vacols_case: vacols_case) }
        before do
          legacy_appeal.tasks.of_type(:JudgeAssignTask).each(&:completed!)
        end
        it "returns true" do
          expect(subject.ok_to_redistribute?).to eq true
        end
      end
      context "when there is an open ScheduleHearingTask and an open parent HearingTask" do
        let(:legacy_appeal) { create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: vacols_case) }

        it "returns false so that appeal is manually addressed" do
          expect(subject.ok_to_redistribute?).to eq false
        end
      end
      context "when there is an open ScheduleHearingTask and a cancelled parent HearingTask" do
        let(:legacy_appeal) { create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: vacols_case) }
        before do
          legacy_appeal.tasks.of_type(:HearingTask).each(&:cancelled!)
        end
        it "returns false because of open task" do
          expect(subject.ok_to_redistribute?).to eq false
        end
      end
      context "when there is a cancelled ScheduleHearingTask, which causes a cancelled parent HearingTask" do
        let(:legacy_appeal) { create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: vacols_case) }
        before do
          legacy_appeal.tasks.of_type(:ScheduleHearingTask).each(&:cancelled!)
        end
        it "returns true" do
          expect(subject.ok_to_redistribute?).to eq true
        end
      end
      context "when there is a completed ScheduleHearingTask, which causes a completed parent HearingTask" do
        let(:legacy_appeal) { create(:legacy_appeal, :with_schedule_hearing_tasks, vacols_case: vacols_case) }
        before do
          legacy_appeal.tasks.of_type(:ScheduleHearingTask).each(&:completed!)
        end
        it "returns true" do
          expect(subject.ok_to_redistribute?).to eq true
        end
      end
    end
  end
end
