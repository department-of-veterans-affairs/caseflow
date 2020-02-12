# frozen_string_literal: true

describe Allocation, :postgres do
  let(:ro_schedule_period) { create(:ro_schedule_period) }

  context ".import_allocation" do
    it "imports allocations" do
      expect(Allocation.where(schedule_period: ro_schedule_period).count).to eq(56)
    end
  end
end
