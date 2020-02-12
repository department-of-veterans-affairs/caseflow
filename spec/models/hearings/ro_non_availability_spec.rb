# frozen_string_literal: true

describe RoNonAvailability, :postgres do
  let(:ro_schedule_period) { create(:ro_schedule_period) }

  context ".import_ro_non_availability" do
    it "imports ro non-availability days" do
      expect(RoNonAvailability.where(schedule_period: ro_schedule_period).count).to eq(223)
    end
  end
end
