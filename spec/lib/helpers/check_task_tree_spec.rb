# frozen_string_literal: true

require "helpers/check_task_tree"

describe "CheckTaskTree" do
  let(:appeal) { create(:appeal) }
  subject { CheckTaskTree.new(appeal) }

  describe "#check" do
    context "..." do
      it "..." do
        errors, warnings = subject.check
      end
    end
  end
end
