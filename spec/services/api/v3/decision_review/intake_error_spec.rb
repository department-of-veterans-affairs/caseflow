# frozen_string_literal: true

describe Api::V3::DecisionReview::IntakeError do
  describe ".first_error_code" do
    subject { described_class.first_error_code(array) }

    context do
      let(:array) { [-1, nil, "hello", :goodbye] }
      it { is_expected.to eq(-1) }
    end

    context do
      let(:array) { [nil, "banana", :apple] }
      it { is_expected.to eq :banana }
    end

    context do
      let(:array) { [false, []] }
      it { is_expected.to eq [] }
    end

    context do
      let(:array) { [nil, [], :this_error] }
      it { is_expected.to eq [] }
    end

    context do
      let(:array) { [{}, Struct.new(:error_code).new(-1)] }
      it { is_expected.to eq({}) }
    end

    context do
      let(:array) { [nil, false, Struct.new(:error_code).new(-1)] }
      it { is_expected.to eq(-1) }
    end
  end

  describe ".first_non_nil" do
    subject { described_class.first_non_nil(array) }

    context do
      let(:array) { [false, nil] }
      it { is_expected.to be false }
    end

    context do
      let(:array) { [nil, nil, false] }
      it { is_expected.to be false }
    end

    context do
      let(:array) { [-1, false] }
      it { is_expected.to be(-1) }
    end
  end

  describe ".new_from_first_error_code" do
    subject { described_class.new_from_first_error_code(array).passed_in_object }

    context do
      let(:array) { [-1, nil, "hello", :goodbye] }
      it { is_expected.to eq(-1) }
    end

    context do
      let(:array) { [nil, "banana", :apple] }
      it { is_expected.to eq :banana }
    end

    context do
      let(:array) { [false, []] }
      it { is_expected.to eq [] }
    end

    context do
      let(:array) { [nil, [], :this_error] }
      it { is_expected.to eq [] }
    end

    context do
      let(:array) { [{}, Struct.new(:error_code).new(-1)] }
      it { is_expected.to eq({}) }
    end

    context do
      let(:array) { [nil, false, Struct.new(:error_code).new(-1)] }
      it { is_expected.to eq(-1) }
    end

    context "no error codes (nothing truthy)" do
      let(:array) { [nil, nil, false] }
      it { is_expected.to be false }
    end
  end

  describe "::KNOWN_ERRORS" do
    subject { described_class::KNOWN_ERRORS }

    it { is_expected.to be_an Array }
    it { is_expected.not_to be_empty }
    it { is_expected.to all be_an Array }
    it do
      subject.all? do |error_array|
        string = "    #{error_array.inspect}"
        string = (string.length > 60) ? "#{string[0..60]}..." : string
        puts string
        puts "      has length 3"
        expect(error_array.length).to be 3
        puts "      first is an Integer"
        expect(error_array.first).to be_an Integer
        puts "      >= 400"
        expect(error_array.first).to be >= 400
        puts "      second is a Symbol"
        expect(error_array.second).to be_a Symbol
        puts "      third is a String"
        expect(error_array.third).to be_a String
      end
    end
  end

  describe "::UNKNOWN_ERROR" do
    subject { described_class::UNKNOWN_ERROR }

    it { is_expected.to be_an Array }
    it { expect(subject.length).to be 3 }
    it { expect(subject.first).to be_an Integer }
    it { expect(subject.first).to be >= 400 }
    it { expect(subject.second).to be_a Symbol }
    it { expect(subject.third).to be_a String }
  end

  describe "::KNOWN_ERRORS_BY_CODE" do
    subject { described_class::KNOWN_ERRORS_BY_CODE }

    it { is_expected.to be_a Hash }
    it { is_expected.not_to be_empty }
    it do
      subject.all? do |error_code, error_array|
        puts "    #{error_code.inspect}"
        puts "      is a Symbol"
        expect(error_code).to be_a Symbol
        string = "    #{error_array.inspect}"
        string = (string.length > 60) ? "#{string[0..60]}..." : string
        puts string
        puts "      has length 3"
        expect(error_array.length).to be 3
        puts "      first is an Integer"
        expect(error_array.first).to be_an Integer
        puts "      >= 400"
        expect(error_array.first).to be >= 400
        puts "      second is a Symbol"
        expect(error_array.second).to be_a Symbol
        puts "      third is a String"
        expect(error_array.third).to be_a String
      end
    end
  end

  context "known error" do
    let(:error_array) { described_class::KNOWN_ERRORS.first }
    let(:error_code) { error_array.second }
    let(:intake_error) { described_class.new(error_code) }

    describe("#status") { it { expect(intake_error.status).to eq error_array.first } }
    describe("#code") { it { expect(intake_error.code).to eq error_code } }
    describe("#title") { it { expect(intake_error.title).to eq error_array.third } }
    describe("#error_code") { it { expect(intake_error.error_code).to eq error_code } }

    context "unknown error" do
      let(:error_code) { %w[h e l l o] }
      let(:unknown_error) { described_class::UNKNOWN_ERROR }

      describe("#status") { it { expect(intake_error.status).to eq unknown_error.first } }
      describe("#code") { it { expect(intake_error.code).to eq unknown_error.second } }
      describe("#title") { it { expect(intake_error.title).to eq unknown_error.third } }
      describe("#error_code") { it { expect(intake_error.error_code).to eq error_code } }
    end
  end

  describe "#detail" do
    subject { described_class.new(error_code, detail).detail }

    context "with a valid error code" do
      let(:error_code) { described_class::KNOWN_ERRORS.first.second }

      context "truthy detail" do
        let(:detail) { "this" }
        it { is_expected.to eq detail }
      end

      context "nil detail" do
        let(:detail) { nil }
        it { is_expected.to eq detail }
      end

      context "no detail passed in at all" do
        subject { described_class.new(error_code).detail }
        it { is_expected.to eq nil }
      end
    end

    context "with an invalid error code" do
      let(:error_code) { %w[h e l l o] }

      context "truthy detail" do
        let(:detail) { "this" }
        it { is_expected.to eq detail }
      end

      context "nil detail" do
        let(:detail) { nil }
        it { is_expected.to eq detail }
      end

      context "no detail passed in at all" do
        subject { described_class.new(error_code).detail }
        it { is_expected.to eq nil }
      end
    end
  end

  describe "#passed_in_object" do
    subject { described_class.new(object).passed_in_object }

    context do
      let(:object) { %w[h e l l o] }
      it { is_expected.to be object }
    end

    context do
      let(:object) { described_class::KNOWN_ERRORS.first.second }
      it { is_expected.to be object }
    end

    context do
      let(:object) { "hello" }
      it { is_expected.to be object }
    end

    context do
      let(:object) { Struct.new(:error_code).new("banana") }
      it { is_expected.to be object }
    end

    context do
      let(:object) { nil }
      it { is_expected.to be object }
    end
  end

  describe "#to_h" do
    subject { described_class.new(error_code, detail).to_h }

    context "unknown error" do
      let(:error_code) { %w[h e l l o] }
      let(:detail) { "Texas" }

      let(:unknown_error) { described_class.new }

      it do
        is_expected.to eq(
          status: unknown_error.status,
          code: unknown_error.code,
          title: unknown_error.title,
          detail: detail
        )
      end

      context "nil detail" do
        let(:detail) { nil }
        it do
          is_expected.to eq(
            status: unknown_error.status,
            code: unknown_error.code,
            title: unknown_error.title
          )
        end
      end

      context "no detail passed in at all" do
        subject { described_class.new(error_code).to_h }
        it do
          is_expected.to eq(
            status: unknown_error.status,
            code: unknown_error.code,
            title: unknown_error.title
          )
        end
      end
    end

    context "known error" do
      let(:error_code) { described_class::KNOWN_ERRORS.first.second }
      let(:detail) { "Maine" }

      let(:known_error) { described_class.new(error_code) }

      it do
        is_expected.to eq(
          status: known_error.status,
          code: known_error.code,
          title: known_error.title,
          detail: detail
        )
      end

      context "nil detail" do
        let(:detail) { nil }
        it do
          is_expected.to eq(
            status: known_error.status,
            code: known_error.code,
            title: known_error.title
          )
        end
      end

      context "no detail passed in at all" do
        subject { described_class.new(error_code).to_h }
        it do
          is_expected.to eq(
            status: known_error.status,
            code: known_error.code,
            title: known_error.title
          )
        end
      end
    end
  end

  context do
    let(:class_method) { described_class.error_code(val) }
    let(:instance_method) { described_class.new(val).error_code }

    let(:val) { :hello }
    describe(".error_code") { it { expect(class_method).to eq val } }
    describe("#error_code") { it { expect(instance_method).to eq val } }

    context "not a symbol but can .to_sym" do
      let(:val) { "banana" }
      describe(".error_code") { it { expect(class_method).to eq val.to_sym } }
      describe("#error_code") { it { expect(instance_method).to eq val.to_sym } }
    end

    context "not a symbol and CANNOT .to_sym" do
      let(:val) { -1 }
      describe(".error_code") { it { expect(class_method).to eq val } }
      describe("#error_code") { it { expect(instance_method).to eq val } }
    end

    context "has an error_code method" do
      let(:val) { Struct.new(:error_code).new(error_code) }

      let(:error_code) { "strawberry" }
      describe(".error_code") { it { expect(class_method).to eq error_code.to_sym } }
      describe("#error_code") { it { expect(instance_method).to eq error_code.to_sym } }

      context "error_code returns something that CANNOT .to_sym" do
        let(:error_code) { -2 }
        describe(".error_code") { it { expect(class_method).to eq error_code } }
        describe("#error_code") { it { expect(instance_method).to eq error_code } }
      end
    end

    context "nil" do
      let(:val) { nil }
      describe(".error_code") { it { expect(class_method).to eq val } }
      describe("#error_code") { it { expect(instance_method).to eq val } }
    end
  end
end
