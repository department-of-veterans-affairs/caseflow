# frozen_string_literal: true

class RemandReason < CaseflowRecord
  validates :code, inclusion: { in: Constants::AMA_REMAND_REASONS_BY_ID.values.map(&:keys).flatten }
  validates :post_aoj, inclusion: { in: [true, false] }
  belongs_to :decision_issue
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: remand_reasons
#
#  id                :bigint           not null, primary key
#  code              :string
#  post_aoj          :boolean
#  created_at        :datetime         not null
#  updated_at        :datetime         not null, indexed
#  decision_issue_id :integer          indexed
#
# Foreign Keys
#
#  fk_rails_4de9f23727  (decision_issue_id => decision_issues.id)
#
