# frozen_string_literal: true

describe TimedHoldTask do
  describe ".create!" do
    # TODO: Test validations
    context "when on_hold task is assigned to a person" do
      let(:task) { FactoryBot.create(:task, :on_hold, type: "Task") }

      it "should not change the task's status" do
        # TODO: Write this test
      end
    end
  end
end
