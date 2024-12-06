# frozen_string_literal: true

require "rails_helper"

RSpec.describe SchedulableCutoffDate, type: :model do
  let(:user) { create(:user) }
  let(:schedulable_date) { create(:schedulable_cutoff_date, created_by_id: user.id) }
  it "fields are showing proper values" do
    expect(schedulable_date.as_json.except("id")).to eq(
      { created_at: schedulable_date.created_at, updated_at: schedulable_date.updated_at,
        created_by_id: schedulable_date.created_by_id, cutoff_date: schedulable_date.cutoff_date }.as_json
    )
  end
end
