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

  describe "ETL::Record.check_equal" do
    context "when check_equal is given unequal values" do
      subject { ETL::Record.check_equal(100, "some_attribute", 20, 4) }
      let(:syncer) { MySyncer.new(etl_build: etl_build) }
      let(:slack_service) { SlackService.new(url: "http://www.example.com") }
      before do
        allow(SlackService).to receive(:new).and_return(slack_service)
        allow(slack_service).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }
      end
      it "sends alert to Slack" do
        subject
        syncer.dump_messages_to_slack(ETL::Record)
        expect(slack_service).to have_received(:send_notification)
          .with("100: Expected some_attribute to equal 20 but got 4",
                "ETL::Record", "#appeals-data-workgroup")
        expect(ETL::Record.messages).to eq nil
      end
    end
  end
end
