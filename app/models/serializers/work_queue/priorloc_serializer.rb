# frozen_string_literal: true

class WorkQueue::PriorlocSerializer
  include FastJsonapi::ObjectSerializer
  extend Helpers::AppealHearingHelper

  attribute :assigned_by
  attribute :assigned_at
  attribute :location
  attribute :sub_location
  attribute :location_staff
  attribute :created_at
  attribute :closed_at
  attribute :vacols_id
  attribute :exception_flag

end
