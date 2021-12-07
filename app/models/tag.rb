# frozen_string_literal: true

class Tag < CaseflowRecord
  has_many :documents_tags
  has_many :documents, through: :documents_tags

  validates :text, presence: true
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: tags
#
#  id         :integer          not null, primary key
#  text       :string           indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null, indexed
#
