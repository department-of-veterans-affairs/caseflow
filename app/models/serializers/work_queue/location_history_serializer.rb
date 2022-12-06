# frozen_string_literal: true

class WorkQueue::LocationHistorySerializer
  include FastJsonapi::ObjectSerializer
  extend Helpers::AppealHearingHelper

  attribute :assigned_by
  attribute :assigned_at
  attribute :location
  attribute :sub_location
  attribute :location_staff
  attribute :location_date_in
  attribute :location_date_out
  attribute :folder
  attribute :exception_flag

end
