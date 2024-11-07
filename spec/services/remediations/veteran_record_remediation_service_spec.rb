# frozen_string_literal: true

RSpec.describe Remediations::VeteranRecordRemediationService do
  describe "#remediate!" do
    let(:before_fn) { "123456789" }
    let(:after_fn) { "987654321" }
    let(:service) { described_class.new(before_fn, after_fn) }

    before do
      allow(FixfileNumberCollections).to receive(:grab_collections).with(before_fn).and_return(collections)
      allow(collections.first).to receive(:update!).with(after_fn)
    end

    context "when collections have records" do
      let(:collection) { instance_double(FixFileNumberWizard::Collection, count: 2) }
      let(:collections) { [collection] }

      it "calls update on each collection" do
        expect(collection).to receive(:update!).with(after_fn)
        service.remediate!
      end
    end

    context "when collections are empty" do
      let(:collections) { [] }

      it "does not raise an error and completes successfully" do
        expect { service.remediate! }.not_to raise_error
      end
    end

    xcontext "when an error occurs during update" do
      let(:collection) { instance_double(FixFileNumberWizard::Collection, count: 2) }
      let(:collections) { [collection] }

      before do
        allow(collection).to receive(:update!).with(after_fn).and_raise(ActiveRecord::RecordInvalid.new("Invalid record"))
      end

      xit "raises an ActiveRecord::RecordInvalid error" do
        expect { service.remediate! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
