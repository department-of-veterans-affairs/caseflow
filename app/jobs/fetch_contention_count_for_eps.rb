# This job will fetch the number of contentions for every
# EP known to Intake
class FetchContentionCountForEps < ActiveJob::Base
  queue_as :low_priority

end
