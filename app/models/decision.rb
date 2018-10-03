class Decision < ApplicationRecord
  belongs_to :appeal
  validates :citation_number, format: { with: /\AA\d{8}\Z/i }
end
