# frozen_string_literal: true

describe "Timezone Initializer" do
  describe "Timezone Overrides" do
    subject { ActiveSupport::TimeZone.find_tzinfo(tz_name).utc_offset }

    context "Asia/Manila" do
      let(:tz_name) { "Asia/Manila" }

      it { is_expected.to eq 28_800 }
    end
  end

  describe "Timezone Aliases" do
    subject do
      corresponding_tz = TIMEZONE_ALIASES[tz_name]

      ActiveSupport::TimeZone.find_tzinfo(corresponding_tz).utc_offset
    end

    context "America/Boise" do
      let(:tz_name) { "America/Boise" }
      let(:comparable_offset) do
        ActiveSupport::TimeZone.find_tzinfo("America/Denver").utc_offset
      end

      it { is_expected.to eq comparable_offset }
    end

    context "America/Kentucky/Louisville" do
      let(:tz_name) { "America/Kentucky/Louisville" }
      let(:comparable_offset) do
        ActiveSupport::TimeZone.find_tzinfo("America/New_York").utc_offset
      end

      it { is_expected.to eq comparable_offset }
    end
  end
end
