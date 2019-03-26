# frozen_string_literal: true

class DocumentView < ApplicationRecord
  belongs_to :document
  belongs_to :user
end
