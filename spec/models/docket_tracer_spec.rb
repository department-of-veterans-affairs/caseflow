# frozen_string_literal: true

require "./spec/support/shared_context/shared_context_docket_dates.rb"

describe DocketSnapshot, :all_dbs do
  before do
    Timecop.freeze(Time.utc(2015, 1, 30, 12, 0, 0))
  end

  include_context "docket dates", include_shared: true

  let(:snapshot) { DocketSnapshot.create }
  let(:first_tracer) { snapshot.docket_tracers.first }
  let(:second_tracer) { snapshot.docket_tracers.second }
  let(:last_tracer) { snapshot.docket_tracers.last }

  context "#at_front" do
    it "should be true for an appeal with a form 9 date older than the latest docket month" do
      expect(first_tracer.at_front).to be_truthy
    end

    it "should be true for an appeal with a form 9 date equal to the latest docket month" do
      expect(second_tracer.at_front).to be_truthy
    end

    it "should be false for an appeal with a form 9 date newer than the latest docket month" do
      expect(last_tracer.at_front).to be_falsey
    end
  end

  context "#to_hash" do
    subject { second_tracer.to_hash }

    it "includes the expected attributes" do
      expect(subject[:front]).to eq(true)
      expect(subject[:total]).to eq(123_456)
      expect(subject[:ahead]).to eq(13_456)
      expect(subject[:ready]).to eq(8456)
      expect(subject[:month]).to eq(11.months.ago.to_date.beginning_of_month)
      expect(subject[:docketMonth]).to eq(11.months.ago.to_date.beginning_of_month)
      expect(subject[:eta]).to eq(nil)
    end
  end
end
