# frozen_string_literal: true

##
# Task that will serve as the parent task for the entirety of the pre docket workflow. This task will be assigned to 
# the Bva organization and remain "on hold" until the AssessDocumentationTask is completed.

class PreDocketTask < Task
end
