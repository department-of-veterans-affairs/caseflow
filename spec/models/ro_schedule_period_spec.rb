# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe RoSchedulePeriod, :postgres do
  let(:ro_schedule_period) { create(:ro_schedule_period) }

  context "validate_spreadsheet" do
    subject { ro_schedule_period.validate_spreadsheet }

    it { is_expected.to be_truthy }
  end

  context "Allocate RO Days Per Given Schedule" do
    subject { ro_schedule_period.algorithm_assignments }

    it "create schedule" do
      is_expected.to be_truthy
    end
  end
end
