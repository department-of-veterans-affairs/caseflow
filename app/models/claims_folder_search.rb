# frozen_string_literal: true

class ClaimsFolderSearch < CaseflowRecord
  belongs_to :appeal, polymorphic: true
  belongs_to :user
end
