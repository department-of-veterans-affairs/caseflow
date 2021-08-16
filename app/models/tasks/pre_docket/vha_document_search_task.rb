# frozen_string_literal: true

##
# When there is a PreDocket task, it means that an intake needs additional review before the decision review
# can proceed to being worked. Once the PreDocket task is complete, the review can be docketed (for appeals) or
# established (for claim reviews). The BVA Intake team may also cancel the review if after additional review, it
# is not ready to continue to being worked.

class VhaDocumentSearchTask < Task
  
end
