# frozen_string_literal: true

describe SameAppealSubstitutionTasksFactory, :postgres do
  describe "#create_substitute_tasks!" do
    context "when an appeal has already been distributed" do
      let(:judge) { create(:user, :judge) }
      let(:selected_task_ids) { [] }

      subject { SameAppealSubstitutionTasksFactory.new(appeal, selected_task_ids).create_substitute_tasks! }

      context "when it is a hearing lane appeal with hearing tasks selected" do
        let!(:appeal) do
          create(:appeal,
                 :hearing_docket,
                 :assigned_to_judge,
                 associated_judge: judge)
        end
        let!(:selected_task) { appeal.tasks.of_type(:ScheduleHearingTask)[0] }
        let(:selected_task_ids) { [selected_task.id] }
        it "sends the case back to distribution" do
          subject
          expect(appeal.ready_for_distribution?).to be true
        end
      end
    end
  end
end
