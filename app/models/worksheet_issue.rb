# frozen_string_literal: true

# Worksheet Issue table represents the worksheet data entered
# by the judge, it is not an official determination on the issue
class WorksheetIssue < CaseflowRecord
  acts_as_paranoid

  belongs_to :appeal, class_name: "LegacyAppeal"
  belongs_to :hearing, foreign_key: :appeal_id, primary_key: :appeal_id

  validates :appeal, :vacols_sequence_id, presence: true

  class << self
    def create_from_issue(appeal, issue)
      WorksheetIssue.find_or_create_by(appeal: appeal, vacols_sequence_id: issue.vacols_sequence_id).tap do |record|
        record.update(notes: issue.note,
                      description: issue.formatted_program_type_levels,
                      disposition: issue.formatted_disposition,
                      from_vacols: true)
      end
    end
  end
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: worksheet_issues
#
#  id                 :integer          not null, primary key
#  allow              :boolean          default(FALSE)
#  deleted_at         :datetime         indexed
#  deny               :boolean          default(FALSE)
#  description        :string
#  dismiss            :boolean          default(FALSE)
#  disposition        :string
#  from_vacols        :boolean
#  notes              :string
#  omo                :boolean          default(FALSE)
#  remand             :boolean          default(FALSE)
#  reopen             :boolean          default(FALSE)
#  created_at         :datetime
#  updated_at         :datetime         indexed
#  appeal_id          :integer          indexed
#  vacols_sequence_id :string
#
# Foreign Keys
#
#  fk_rails_a5ba28a6da  (appeal_id => legacy_appeals.id)
#
