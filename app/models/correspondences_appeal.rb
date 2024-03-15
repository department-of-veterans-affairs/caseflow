# frozen_string_literal: true

class CorrespondencesAppeal < ApplicationRecord
  belongs_to :correspondence
  belongs_to :appeal
end
