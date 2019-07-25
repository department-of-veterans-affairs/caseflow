# coding: utf-8
# frozen_string_literal: true

require "rails_helper"

describe ErrorRenderHash do
  context ".render_hash a single error" do
    subject do
      ErrorRenderHash.new status: 409, title: "Intake in progress", code: "duplicate_intake_in_progress"
    end

    it "should return a nearly identical render hash" do
      expect(subject.render_hash).to eq(
        json: {
          errors: [{
            status: 409, title: "Intake in progress", code: "duplicate_intake_in_progress"
          }.as_json]
        },
        status: 409
      )
    end
  end

  context ".render_hash a single error with an invalid symbol status" do
    subject do
      ErrorRenderHash.new status: :xyz, title: "Intake in progress", code: "duplicate_intake_in_progress"
    end

    it ["should return a render hash with that has Error's DEFAULT_STATUS,",
        "but the individual error should retain the invalid status"].join(" ") do
      expect(subject.render_hash).to eq(
        json: {
          errors: [{
            status: "xyz", title: "Intake in progress", code: "duplicate_intake_in_progress"
          }.as_json]
        },
        status: ErrorRenderHash::Error::DEFAULT_STATUS
      )
    end
  end

  context ".render_hash after initializing with no arguments" do
    subject { ErrorRenderHash.new }

    it "should return a render hash with the default values for an error" do
      expect(subject.render_hash).to eq(
        json: {
          errors: [{
            status: ErrorRenderHash::Error::DEFAULT_STATUS,
            title: ErrorRenderHash::Error::DEFAULT_TITLE,
            code: ErrorRenderHash::Error::DEFAULT_CODE
          }.as_json]
        },
        status: ErrorRenderHash::Error::DEFAULT_STATUS
      )
    end
  end

  context ".render_hash with multiple errors" do
    subject do
      ErrorRenderHash.new [
        {status: 409, title: "Intake in progress", code: "duplicate_intake_in_progress"},
        {status: "403", title: "Veteran File inaccessible", code: "veteran_not_accessible"},
        {
          status: :unprocessable_entity,
          title: "Issue is ineligible because it has a prior decision date that’s older than 1 year",
          code: "untimely"
        }
      ]
    end

    it "should return a render hash with the default values for an error" do
      expect(subject.render_hash).to eq(
        json: {
          errors: [
            {status: 409, title: "Intake in progress", code: "duplicate_intake_in_progress"},
            {status: "403", title: "Veteran File inaccessible", code: "veteran_not_accessible"},
            {
              status: :unprocessable_entity,
              title: "Issue is ineligible because it has a prior decision date that’s older than 1 year",
              code: "untimely"
            }
          ].as_json
        },
        status: 422
      )
    end
  end
end
