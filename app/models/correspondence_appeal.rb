# frozen_string_literal: true

class CorrespondenceAppeal < ApplicationRecord
  belongs_to :correspondence
  belongs_to :appeal
end
