# frozen_string_literal: true

require "rails_helper"

describe IhpTasksFactory, :postgres do
  let(:appeal) { create(:appeal, :active) }
  let(:parent_task) { create(:task, appeal: appeal) }
  let(:ihp_tasks_factory) { IhpTasksFactory.new(parent_task) }

  describe "#create_ihp_tasks!" do
    subject { ihp_tasks_factory.create_ihp_tasks! }

    context "when there is an open pre-docket task" do
      before do
        allow(appeal.status).to receive(:open_pre_docket_task?).and_return(true)
      end

      it "cancels existing IHP tasks" do
        vso_organization = create(:vso)
        allow(vso_organization).to receive(:should_write_ihp?).with(appeal).and_return(true)
        ihp_task = create(:informal_hearing_presentation_task, appeal: appeal, assigned_to: vso_organization)
        allow(appeal).to receive(:representatives).and_return([vso_organization])

        result = subject

        expect(ihp_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
        expect(result).to eq([])
      end

      it "does not create new IHP tasks" do
        allow(appeal).to receive(:representatives).and_return([create(:vso)])

        expect { subject }.not_to change(InformalHearingPresentationTask, :count)
        expect(subject).to eq([])
      end
    end

    context "when there is no open pre-docket task" do
      before do
        allow(appeal.status).to receive(:open_pre_docket_task?).and_return(false)
      end

      it "creates new IHP tasks for representatives that should write IHP" do
        vso_organization = create(:vso)
        allow(vso_organization).to receive(:should_write_ihp?).with(appeal).and_return(true)
        allow(appeal).to receive(:representatives).and_return([vso_organization])

        expect { subject }.to change { InformalHearingPresentationTask.count }.by(1)
        expect(InformalHearingPresentationTask.last.assigned_to).to eq(vso_organization)
      end

      it "does not create IHP tasks for representatives that should not write IHP" do
        vso_organization = create(:vso)
        allow(vso_organization).to receive(:should_write_ihp?).with(appeal).and_return(false)
        allow(appeal).to receive(:representatives).and_return([vso_organization])

        expect { subject }.not_to change(InformalHearingPresentationTask, :count)
      end

      it "does not create duplicate IHP tasks" do
        vso_organization = create(:vso)
        ihp_task = create(:informal_hearing_presentation_task, appeal: appeal, assigned_to: vso_organization)
        allow(vso_organization).to receive(:should_write_ihp?).with(appeal).and_return(true)
        allow(appeal).to receive(:representatives).and_return([vso_organization])

        expect { subject }.not_to change(InformalHearingPresentationTask, :count)
        expect(InformalHearingPresentationTask.last).to eq(ihp_task)
      end
    end
  end
end
