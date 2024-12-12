# frozen_string_literal: true

RSpec.describe CorrespondenceIntake, type: :model do
  describe "relationships" do
    it { CorrespondenceIntake.reflect_on_association(:task).macro.should eq(:belongs_to) }
  end

  describe "Record entry" do
    let(:current_user) { create(:inbound_ops_team_supervisor) }
    before do
      CorrespondenceType.create!(
        name: "a correspondence type"
      )

      FactoryBot.create(:veteran)

      User.authenticate!(user: current_user)
    end

    it "can be created" do
      user = create(:user)
      InboundOpsTeam.singleton.add_user(user)
      correspondence = create(:correspondence)
      task = CorrespondenceIntakeTask.create_from_params(correspondence&.root_task, user)
      subject = CorrespondenceIntake.create!(
        task_id: task.id,
        current_step: 1,
        redux_store: {}
      )

      expect(subject).to be_a(CorrespondenceIntake)
    end

    it "validates :task_id" do
      expect { CorrespondenceIntake.create! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "validates that the associated task is a CorrespondenceIntakeTask" do
      correspondence = create(:correspondence)
      task = correspondence&.root_task

      expect { CorrespondenceIntake.create!(task_id: task.id).to raise_error(ActiveRecord::RecordInvalid) }
    end
  end
end
