# frozen_string_literal: true

describe Allocation do
  let(:ro_schedule_period) { create(:ro_schedule_period) }

  context ".import_allocation" do
    it "imports allocations" do
      expect(Allocation.where(schedule_period: ro_schedule_period).count).to eq(57)
    end
  end
end
