# frozen_string_literal: true

describe ETL::Syncer, :etl do
  class DummyEtlClass < ETL::Record
  end

  class MySyncer < ETL::Syncer
    def origin_class
      ::User
    end

    def target_class
      DummyEtlClass
    end
  end

  let(:etl_build) { ETL::Build.create }
  subject { described_class.new(etl_build: etl_build) }

  describe "#origin_class" do
    it "raises error when called on abstract class" do
      expect { subject.origin_class }.to raise_error(RuntimeError)
    end
  end

  describe "#target_class" do
    it "raises error when called on abstract class" do
      expect { subject.target_class }.to raise_error(RuntimeError)
    end
  end

  describe "#call" do
    before do
      dummy_target = double("dummy")
      allow(dummy_target).to receive(:save!) { @dummy_saved = true }
      allow(dummy_target).to receive(:persisted?) { true }
      allow(DummyEtlClass).to receive(:sync_with_original) { dummy_target }
    end

    context "one stale origin class instance needing sync" do
      let!(:user) { create(:user) }

      subject { MySyncer.new(etl_build: etl_build).call }

      it "saves a new target class instance" do
        subject
        expect(DummyEtlClass).to have_received(:sync_with_original).once
        expect(@dummy_saved).to eq(true)
        expect(etl_build.built).to eq(1)
      end
    end
  end
end
