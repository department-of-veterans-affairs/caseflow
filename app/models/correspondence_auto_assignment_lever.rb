# frozen_string_literal: true

class CorrespondenceAutoAssignmentLever < CaseflowRecord
  has_paper_trail on: [:update, :destroy]
end
