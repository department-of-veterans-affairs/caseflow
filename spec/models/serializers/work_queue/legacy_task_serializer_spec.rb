# frozen_string_literal: true

describe WorkQueue::LegacyTaskSerializer do
  subject { described_class.new(legacy_task) }

  context "Serializing an AttorneyLegacyTask" do
    let!(:legacy_appeal) { LegacyAppeal.create(vacols_id: "1111", vbms_id: "1234") }
    let!(:assigned_user) { create(:user) }
    let(:assigned_by_user) do
      # We do not have a class that accurately represents
      # users that have assigned legacy tasks in VACOLS.
      # This implementation bridges that gap for these tests.
      user = create(:user)
      user.define_singleton_method(:first_name) { "John" }
      user.define_singleton_method(:last_name) { "Smith" }
      user.define_singleton_method(:pg_id) { 1 }
      user
    end
    let(:added_by_user) do
      # We do not have a class that accurately represents
      # users that have added legacy tasks to VACOLS.
      # This implementation bridges that gap for these tests.
      user = create(:user)
      user.define_singleton_method(:name) { full_name }
      user
    end
    let(:task_details) do
      OpenStruct.new(
        vacols_id: legacy_appeal.vacols_id,
        date_due: 3.days.ago,
        assigned_to_location_date: 10.days.ago,
        created_at: 12.days.ago,
        docket_date: nil,
        added_by: added_by_user,
        assigned_by: assigned_by_user
      )
    end
    let(:legacy_task) do
      AttorneyLegacyTask.from_vacols(task_details, legacy_appeal, assigned_user)
    end

    it "the task instructions are an empty array by default" do
      expect(subject.serializable_hash[:data][:attributes][:instructions]).to eq []
    end
  end
end
