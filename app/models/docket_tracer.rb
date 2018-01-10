# == Schema Information
#
# Table name: docket_tracers
#
# id
# created_at
# updated_at
# ahead_count
# ahead_and_ready_count

class DocketTracer < ActiveRecord::Base
  belongs_to :docket_snapshot
end
