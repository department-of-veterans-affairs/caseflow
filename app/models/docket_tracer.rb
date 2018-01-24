class DocketTracer < ActiveRecord::Base
  belongs_to :docket_snapshot
end
