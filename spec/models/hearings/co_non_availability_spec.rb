# frozen_string_literal: true

require "rails_helper"

describe CoNonAvailability do
  let(:ro_schedule_period) { create(:ro_schedule_period) }

  context ".import_co_non_availability" do
    it "imports co non-availability days" do
      expect(CoNonAvailability.where(schedule_period: ro_schedule_period).count).to eq(4)
    end
  end
end
