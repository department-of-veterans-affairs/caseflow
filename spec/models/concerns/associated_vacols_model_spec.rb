require "rails_helper"

describe AssociatedVacolsModel do
  class TestVacolsModelRepository
    class << self
      attr_accessor :fail_load_vacols_data
    end

    def self.load_vacols_data(model)
      return false if fail_load_vacols_data
      model.foo = "bar"
    end
  end

  class TestVacolsModel
    include AssociatedVacolsModel

    vacols_attr_accessor :foo, :bar, :foobar

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
      it { is_expected.to eq("hello") }
    end

    context "ensure setter sets value" do
      it do
        expect(model.foo).to eq("bar")
        model.foo = "hello"
        expect(model.foo).to eq("hello")
      end
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

  context "#turn_off_lazy_loading" do
    let(:foo_value) { "George" }
    before { model.turn_off_lazy_loading(initial_values: { foo: foo_value }) }

    it "will not load data when check_and_load_vacols_data is called" do
      expect(TestVacolsModelRepository).to receive(:load_vacols_data).exactly(0).times
      expect(model.check_and_load_vacols_data!).to be_truthy
    end

    it "will raise an error when a getter is called for a non-initialized variable" do
      expect { model.bar }.to raise_error(AssociatedVacolsModel::LazyLoadingTurnedOffError)
    end

    it "will raise an error when a setter is called for a non-initialized variable" do
      expect { model.bar = 5 }.to raise_error(AssociatedVacolsModel::LazyLoadingTurnedOffError)
    end

    it "will return set initial value when a getter is called for an initialized variable" do
      expect(model.foo).to eq(foo_value)
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
end
