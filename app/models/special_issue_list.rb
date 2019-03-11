# frozen_string_literal: true

class SpecialIssueList < ApplicationRecord
  belongs_to :appeal, polymorphic: true
end
