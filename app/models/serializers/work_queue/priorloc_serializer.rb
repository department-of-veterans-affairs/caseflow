# frozen_string_literal: true

class WorkQueue::PriorlocSerializer
  include FastJsonapi::ObjectSerializer

  attribute :assigned_by
  attribute :assigned_at
  attribute :location_label
  attribute :sub_location
  attribute :location_staff
  attribute :created_at
  attribute :closed_at
  attribute :vacols_id
  attribute :exception_flag
  attribute :with_attorney?
  attribute :with_judge?

end
