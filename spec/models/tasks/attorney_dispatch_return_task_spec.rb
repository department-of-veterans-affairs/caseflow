# frozen_string_literal: true

describe AttorneyDispatchReturnTask do
  context ".create" do
    it "returns the correct label" do
      expect(AttorneyDispatchReturnTask.new.label).to eq(
        COPY::ATTORNEY_DISPATCH_RETURN_TASK_LABEL
      )
    end

    it "returns the correct timeline title" do
      expect(AttorneyDispatchReturnTask.new.timeline_title).to eq(
        COPY::CASE_TIMELINE_ATTORNEY_DISPATCH_RETURN_TASK
      )
    end
  end
end
