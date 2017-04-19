module Caseflow::Error
  class MultipleAppealsByVBMSID < StandardError; end
  class NotEnoughTasksPrepared < StandardError; end
end
