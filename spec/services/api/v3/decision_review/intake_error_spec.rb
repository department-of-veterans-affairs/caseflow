# frozen_string_literal: true

require "rails_helper"

context Api::V3::DecisionReview::IntakeError do
  context "::KNOWN_ERRORS" do
    subject { Api::V3::DecisionReview::IntakeError::KNOWN_ERRORS }
    it "should be an array" do
      expect(subject).to be_kind_of(Array)
    end
    it "should be non-empty" do
      expect(subject.length).to be > 0
    end
  end

  context "::UNKNOWN_ERROR" do
    subject { Api::V3::DecisionReview::IntakeError::UNKNOWN_ERROR }
    it "should be an array" do
      expect(subject).to be_kind_of(Array)
    end
    it "should be non-empty" do
      expect(subject.length).to be > 0
    end
  end

  context "::KNOWN_ERRORS_BY_CODE" do
    subject { Api::V3::DecisionReview::IntakeError::KNOWN_ERRORS_BY_CODE }
    it "should be a hash" do
      expect(subject).to be_kind_of(Hash)
    end
    it "should be non-empty" do
      expect(subject.keys.length).to be > 0
    end
  end

  context ".error_code" do
    it "should return symbol :hello" do
      expect(Api::V3::DecisionReview::IntakeError.error_code(:hello)).to eq(:hello)
    end
    it "should return symbol :hello" do
      expect(Api::V3::DecisionReview::IntakeError.error_code("hello")).to eq(:hello)
    end
    obj = Struct.new(:error_code).new(900)
    it "should return object's error_code (#{obj.error_code})" do
      expect(Api::V3::DecisionReview::IntakeError.error_code(obj)).to eq(
        Api::V3::DecisionReview::IntakeError.error_code(obj.error_code)
      )
    end
  end

  context ".first_that_is_or_has_an_error_code" do
    obj = Struct.new(:error_code).new("cat")
    it "should return first that is or has error_code (#{obj.error_code})" do
      expect(
        Api::V3::DecisionReview::IntakeError.first_that_is_or_has_an_error_code([:hello, obj])
      ).to eq(:hello)
    end
    it "should return first that is or has error_code (#{obj.error_code})" do
      expect(
        Api::V3::DecisionReview::IntakeError.first_that_is_or_has_an_error_code([777, obj])
      ).to eq(obj)
    end
    it "should return first that is or has error_code (#{obj.error_code})" do
      expect(
        Api::V3::DecisionReview::IntakeError.first_that_is_or_has_an_error_code([nil, false])
      ).to eq(nil)
    end
  end

  context ".new" do
    obj_with_invalid_code = Struct.new(:error_code).new("cat")
    obj_with_valid_code = Struct.new(:error_code).new("intake_start_failed")
    it "should be unknown" do
      expect(
        Api::V3::DecisionReview::IntakeError.new(obj_with_invalid_code).as_json.values_at("status", "code", "title")
      ).to eq(Api::V3::DecisionReview::IntakeError::UNKNOWN_ERROR.as_json)
    end
    it "should not raise" do
      expect do
        Api::V3::DecisionReview::IntakeError.new(obj_with_valid_code)
      end.not_to raise_error
    end
  end

  context ".from_first_error_code_found" do
    obj_a = Struct.new(:error_code).new("dog")
    obj_b = Struct.new(:error_code).new("intake_review_failed")
    it "should be unknown" do
      expect(
        Api::V3::DecisionReview::IntakeError.from_first_error_code_found([obj_a, obj_b]).code
      ).to eq(:unknown_error)
    end
    it "should be :intake_review_failed" do
      expect(
        Api::V3::DecisionReview::IntakeError.from_first_error_code_found([obj_b, obj_a]).code
      ).to eq(:intake_review_failed)
    end
    it "should be :intake_review_failed" do
      expect(
        Api::V3::DecisionReview::IntakeError.from_first_error_code_found([nil, obj_b]).code
      ).to eq(:intake_review_failed)
    end
  end
end
