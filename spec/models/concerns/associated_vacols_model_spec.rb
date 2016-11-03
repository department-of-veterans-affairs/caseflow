describe AssociatedVacolsModel do
  class TestVacolsModelRepository
    def self.load_vacols_data(model)
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

  context "#check_and_load_vacols_data!" do
    it do
      TestVacolsModelRepository.should_receive(:load_vacols_data).exactly(1).times
      model.check_and_load_vacols_data!
      model.check_and_load_vacols_data!
    end
  end
end
