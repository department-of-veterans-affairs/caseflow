# frozen_string_literal: true

# Track the path to the ihp draft a vso creates for an appeal and uploads to V:\
# Validates the format of the path based on whether or not the appeal is a legacy or ama appeal
class IhpDraft < CaseflowRecord
  belongs_to :appeal, polymorphic: true
  belongs_to :organization

  validates :appeal, :organization, :path, presence: true
  validate :valid_v_drive_path, on: [:create, :update]

  V_DRIVE_PATH_MATCHER = /^\\\\vacoappbva3\.dva\.va\.gov\\DMDI\$\\VBMS Paperless IHPs\\[A-Z]+\\/.freeze
  AMA_PATH_MATCHER = /AMA IHPs\\.+\.pdf$/.freeze
  LEGACY_PATH_MATCHER = /902\\.+\.pdf$/.freeze

  PATH_MATCHERS = {
    LegacyAppeal.name => LEGACY_PATH_MATCHER,
    Appeal.name => AMA_PATH_MATCHER
  }.freeze

  def self.create_or_update_from_task!(task, path)
    organization = (task.assigned_to_type == Organization.name) ? task.assigned_to : task.parent.assigned_to
    ihp_draft = find_by(appeal: task.appeal, organization: organization)
    path = path.tr("\"", "")

    if ihp_draft
      ihp_draft.update!(path: path)
    else
      ihp_draft = create!(appeal: task.appeal, organization: organization, path: path)
    end

    ihp_draft
  end

  def valid_v_drive_path
    return if appeal && path&.match?(V_DRIVE_PATH_MATCHER) && path&.match?(PATH_MATCHERS[appeal_type])

    errors.add(:path, COPY::INVALID_IHP_DRAFT_PATH)
  end
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: ihp_drafts
#
#  id              :bigint           not null, primary key
#  appeal_type     :string           not null, indexed => [appeal_id, organization_id]
#  path            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  appeal_id       :integer          not null, indexed => [appeal_type, organization_id]
#  organization_id :integer          not null, indexed => [appeal_id, appeal_type]
#
# Foreign Keys
#
#  fk_rails_550cb27209  (organization_id => organizations.id)
#
