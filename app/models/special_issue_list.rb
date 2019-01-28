class SpecialIssueList < ApplicationRecord
  belongs_to :appeal, polymorphic: true
end
