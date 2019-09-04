# frozen_string_literal: true

context Api::V3::DecisionReview::IntakeError do
  # :reek:UtilityFunction:
  def valid_error_array_shape?(array)
    array.is_a?(Array) &&
      array.length == 3 &&
      array.first.is_a?(Integer) &&
      array.first >= 400 &&
      array.second.is_a?(Symbol) &&
      array.third.is_a?(String)
  end

  context "::KNOWN_ERRORS" do
    subject { Api::V3::DecisionReview::IntakeError::KNOWN_ERRORS }

    it "should be a non-empty array of arrays" \
        ", and each array is 3 elements long: Integer >=400, Symbol, and String" do
      expect(subject).to be_an Array
      expect(subject).not_to be_empty
      expect(subject).to all be_an Array
      expect(subject.all? { |error_array| valid_error_array_shape?(error_array) }).to be true
    end
  end

  context "::UNKNOWN_ERROR" do
    subject { Api::V3::DecisionReview::IntakeError::UNKNOWN_ERROR }

    it "should be an array that's 3 elements long: Integer >=400, Symbol, and String" do
      expect(valid_error_array_shape?(subject)).to be true
    end
  end

  context "::KNOWN_ERRORS_BY_CODE" do
    subject { Api::V3::DecisionReview::IntakeError::KNOWN_ERRORS_BY_CODE }

    it("should be a hash") { expect(subject).to be_kind_of(Hash) }

    it("should be non-empty") { expect(subject).not_to be_empty }

    it("should have symbol keys") { expect(subject.keys).to all be_a Symbol }

    it "should have values that are arrays, 3 elements long: Integer >=400, Symbol, and String" do
      expect(subject.values.all? { |error_array| valid_error_array_shape?(error_array) }).to be true
    end
  end

  context ".potential_error_code" do
    it "should return :hello" do
      expect(Api::V3::DecisionReview::IntakeError.potential_error_code(:hello)).to eq(:hello)
    end

    it "should return :hello" do
      expect(Api::V3::DecisionReview::IntakeError.potential_error_code("hello")).to eq(:hello)
    end

    it "should return nil" do
      expect(Api::V3::DecisionReview::IntakeError.potential_error_code(26)).to eq(nil)
    end

    klass = Struct.new(:error_code)
    obj_with_string_error_code = klass.new("dog")
    it "should return :dog" do
      expect(Api::V3::DecisionReview::IntakeError.potential_error_code(obj_with_string_error_code)).to eq(:dog)
    end

    obj_with_false_error_code = klass.new(false)
    it "should return nil" do
      expect(Api::V3::DecisionReview::IntakeError.potential_error_code(obj_with_false_error_code)).to eq(nil)
    end

    nested_obj = klass.new klass.new klass.new :russian_doll
    it "should return nil" do
      expect(Api::V3::DecisionReview::IntakeError.potential_error_code(nested_obj)).to eq(nil)
    end
  end

  context ".find_first_potential_error_code" do
    obj = Struct.new(:error_code).new("cat")

    it "should return :hello" do
      expect(
        Api::V3::DecisionReview::IntakeError.find_first_potential_error_code([:hello, obj])
      ).to eq(:hello)
    end

    it "should return #{obj.error_code}" do
      expect(
        Api::V3::DecisionReview::IntakeError.find_first_potential_error_code([777, obj])
      ).to eq(obj.error_code.to_sym)
    end

    it "should return nil" do
      expect(
        Api::V3::DecisionReview::IntakeError.find_first_potential_error_code([nil, false])
      ).to eq(nil)
    end
  end

  context ".from_first_potential_error_code_found" do
    obj_with_invalid_code = Struct.new(:error_code).new("dog")
    obj_with_valid_code = Struct.new(:error_code).new("intake_review_failed")
    obj_that_returns_nil = Struct.new(:error_code).new(nil)

    it "should be unknown" do
      expect(
        Api::V3::DecisionReview::IntakeError.from_first_potential_error_code_found(
          [obj_with_invalid_code, obj_with_valid_code]
        ).code
      ).to eq(:unknown_error)
    end

    it "should be :intake_review_failed" do
      expect(
        Api::V3::DecisionReview::IntakeError.from_first_potential_error_code_found(
          [obj_with_valid_code, obj_with_invalid_code]
        ).code
      ).to eq(:intake_review_failed)
    end

    it "should be :intake_review_failed" do
      expect(
        Api::V3::DecisionReview::IntakeError.from_first_potential_error_code_found([nil, obj_with_valid_code]).code
      ).to eq(:intake_review_failed)
    end

    it "should be unknown" do
      expect(
        Api::V3::DecisionReview::IntakeError.from_first_potential_error_code_found([obj_that_returns_nil, nil]).code
      ).to eq(:unknown_error)
    end

    it "should be unknown" do
      expect(
        Api::V3::DecisionReview::IntakeError.from_first_potential_error_code_found([nil, obj_that_returns_nil]).code
      ).to eq(:unknown_error)
    end

    it "should be unknown" do
      expect(
        Api::V3::DecisionReview::IntakeError.from_first_potential_error_code_found([nil, false]).code
      ).to eq(:unknown_error)
    end

    it "should raise (array isn't supplied as argument)" do
      expect do
        Api::V3::DecisionReview::IntakeError.from_first_potential_error_code_found(nil).code
      end.to raise_error(NoMethodError)
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
end
