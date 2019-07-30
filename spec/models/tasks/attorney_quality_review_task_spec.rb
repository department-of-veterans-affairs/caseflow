# frozen_string_literal: true

require "rails_helper"

describe AttorneyQualityReviewTask do
  context ".create" do
    it "returns the correct label" do
      expect(AttorneyQualityReviewTask.new.label).to eq(
        COPY::ATTORNEY_QUALITY_REVIEW_TASK_LABEL
      )
    end

    it "returns the correct timeline title" do
      expect(AttorneyQualityReviewTask.new.timeline_title).to eq(
        COPY::CASE_TIMELINE_ATTORNEY_QUALITY_REVIEW_TASK
      )
    end
  end
end
