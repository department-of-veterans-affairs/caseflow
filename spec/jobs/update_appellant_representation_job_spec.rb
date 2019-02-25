require "rails_helper"

describe UpdateAppellantRepresentationJob do
  context "when the job runs successfully" do
    let(:new_task_count) { 3 }
    let(:closed_task_count) { 1 }
    let(:correct_task_count) { 6 }
    let(:error_count) { 0 }

    before do
      vso_for_appeal = {}

      correct_task_count.times do |_|
        appeal, vso = create_appeal_and_vso
        FactoryBot.create(:track_veteran_task, appeal: appeal, assigned_to: vso)
        vso_for_appeal[appeal.id] = [vso]
      end

      new_task_count.times do |_|
        appeal, vso = create_appeal_root_and_vso
        vso_for_appeal[appeal.id] = [vso]
      end

      closed_task_count.times do |_|
        appeal, vso = create_appeal_root_and_vso
        FactoryBot.create(:track_veteran_task, appeal: appeal, assigned_to: vso)
        vso_for_appeal[appeal.id] = []
      end

      allow_any_instance_of(Appeal).to receive(:vsos) { |a| vso_for_appeal[a.id] }
    end

    it "runs the job as expected" do
      expect_any_instance_of(UpdateAppellantRepresentationJob).to receive(:log_info).with(
        anything,
        new_task_count,
        closed_task_count,
        error_count
      )

      UpdateAppellantRepresentationJob.perform_now
    end
  end
end

def create_appeal_root_and_vso
  appeal = FactoryBot.create(:appeal)
  FactoryBot.create(:root_task, appeal: appeal)
  vso = FactoryBot.create(:vso)

  [appeal, vso]
end
