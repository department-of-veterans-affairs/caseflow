# frozen_string_literal: true

class SpecialIssueList < CaseflowRecord
  include HasAppealUpdatedSince

  include BelongsToPolymorphicAppealConcern
  belongs_to_polymorphic_appeal :appeal

  # belongs_to :appeal, polymorphic: true

  # belongs_to :ama_appeal,
  #            -> { includes(:special_issue_list).where(special_issue_lists: { "appeal_type" => "Appeal" }) },
  #            class_name: "Appeal", foreign_key: "appeal_id", optional: true

  # belongs_to :legacy_appeal,
  #            -> { includes(:special_issue_list).where(special_issue_lists: { "appeal_type" => "LegacyAppeal" }) },
  #            class_name: "LegacyAppeal", foreign_key: "appeal_id", optional: true
end
