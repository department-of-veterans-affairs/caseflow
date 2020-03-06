# frozen_string_literal: true

describe AssociatedVacolsModel do
  class TestVacolsModelRepository
    class << self
      attr_accessor :fail_load_vacols_data
    end

    def self.load_vacols_data(model)
      return false if fail_load_vacols_data

      model.foo = "bar"
      model.setteronly = "set"
    end
  end

  class TestVacolsModel
    include AssociatedVacolsModel

    vacols_attr_accessor :foo, :bar, :foobar
    vacols_attr_setter :setteronly
    vacols_attr_getter :getteronly
    attr_accessor :attr

    def self.repository
      TestVacolsModelRepository
    end
  end

  let(:model) { TestVacolsModel.new }

  context ".vacols_attr_accessor" do
    context "getter" do
      subject { model.foo }
      it { is_expected.to eq("bar") }
    end

    context "call setter before first get" do
      before { model.foo = "hello" }
      subject { model.foo }
      it do
        expect(model).to_not receive(:check_and_load_vacols_data!)
        is_expected.to eq("hello")
      end
    end

    it "setters set, getters get values" do
      expect(model.foo).to eq("bar")
      model.foo = "hello"
      expect(model.foo).to eq("hello")

      expect { model.setteronly }.to raise_error(NoMethodError)
      expect { model.setteronly = "test" }.to_not raise_error
      expect { model.getteronly }.to_not raise_error
      expect { model.getteronly = "test" }.to raise_error(NoMethodError)
    end

    it "triggers a call to load data when fields not set " do
      model.bar = "hello"
      expect(Raven).to receive(:capture_exception)
      expect(model.foo).to eq("bar")
    end
  end

  context ".vacols_field?" do
    it "returns true for variables set with vacols_attr_accessor" do
      expect(TestVacolsModel.vacols_field?(:foo)).to be_truthy
    end

    it "returns false for variables set with attr_accessor" do
      expect(TestVacolsModel.vacols_field?(:attr)).to be_falsy
    end

    it "returns false for variables set with only getter" do
      expect(TestVacolsModel.vacols_field?(:getteronly)).to be_falsy
    end

    it "returns false for variables set with only setter" do
      expect(TestVacolsModel.vacols_field?(:setteronly)).to be_falsy
    end
  end

  context ".vacols_setter?" do
    it "returns true for variables set with vacols_attr_accessor" do
      expect(TestVacolsModel.vacols_setter?(:foo)).to be_truthy
    end

    it "returns false for variables set with attr_accessor" do
      expect(TestVacolsModel.vacols_setter?(:attr)).to be_falsy
    end

    it "returns false for variables set with only getter" do
      expect(TestVacolsModel.vacols_setter?(:getteronly)).to be_falsy
    end

    it "returns true for variables set with only setter" do
      expect(TestVacolsModel.vacols_setter?(:setteronly)).to be_truthy
    end
  end

  context ".vacols_getter?" do
    it "returns true for variables set with vacols_attr_accessor" do
      expect(TestVacolsModel.vacols_getter?(:foo)).to be_truthy
    end

    it "returns false for variables set with attr_accessor" do
      expect(TestVacolsModel.vacols_getter?(:attr)).to be_falsy
    end

    it "returns true for variables set with only getter" do
      expect(TestVacolsModel.vacols_getter?(:getteronly)).to be_truthy
    end

    it "returns false for variables set with only setter" do
      expect(TestVacolsModel.vacols_getter?(:setteronly)).to be_falsy
    end
  end

  context "#assign_from_vacols" do
    before { model.assign_from_vacols(foo: 1, bar: 2, foobar: 3) }
    subject { [model.foo, model.bar, model.foobar] }
    it { is_expected.to eq([1, 2, 3]) }
  end

  context "#vacols_record_exists?" do
    subject { model.vacols_record_exists? }

    it "loads VACOLS data and returns the result" do
      is_expected.to eq(true)
      expect(model.foo).to eq("bar")
    end
  end

  context "#check_and_load_vacols_data!" do
    subject { model.check_and_load_vacols_data! }

    it "only loads the data from VACOLS once" do
      is_expected.to be_truthy

      expect(TestVacolsModelRepository).to receive(:load_vacols_data).exactly(0).times
      expect(model.check_and_load_vacols_data!).to be_truthy
    end

    context "when VACOLS load fails" do
      before { TestVacolsModelRepository.fail_load_vacols_data = true }

      it "returns false and only attempts VACOLS load once" do
        is_expected.to eq(false)

        expect(TestVacolsModelRepository).to receive(:load_vacols_data).exactly(0).times
        expect(model.check_and_load_vacols_data!).to eq(false)
      end
    end
  end

  context "#field_set?" do
    subject { model.field_set?(:foo) }

    it "returns false when nothing is set" do
      is_expected.to be_falsy
    end

    context "when a different field has been set" do
      before do
        model.bar = "value"
      end

      it "returns false for the current field" do
        is_expected.to be_falsy
      end
    end

    context "when field has been set" do
      before do
        model.foo = "value"
      end

      it "returns true" do
        is_expected.to be_truthy
      end
    end
  end

  context "#mark_field_as_set" do
    it "field_set? returns true after running mark_field_as_set" do
      expect(model.field_set?(:foo)).to be_falsy
      model.mark_field_as_set(:foo)
      expect(model.field_set?(:foo)).to be_truthy
    end
  end
end
