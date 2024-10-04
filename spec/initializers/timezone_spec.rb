# frozen_string_literal: true

describe "Timezone Overrides" do
  subject do
    ActiveSupport::TimeZone.find_tzinfo(tz_name).utc_offset
  end

  let(:comparable_offset) do
    ActiveSupport::TimeZone.find_tzinfo(tz_name_to_compare_with).utc_offset
  end

  context "America/Boise" do
    let(:tz_name) { "America/Boise" }
    let(:tz_name_to_compare_with) { "America/Denver" }

    it { subject.to eq comparable_offset }
  end

  context "America/Kentucky/Louisville" do
    let(:tz_name) { "America/Kentucky/Louisville" }
    let(:tz_name_to_compare_with) { "America/New_York" }

    it { subject.to eq comparable_offset }
  end

  context "Asia/Manila" do
    let(:tz_name) { "Asia/Manila" }

    it { subject.to eq 28_800 }
  end
end
