# frozen_string_literal: true

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

  def valid_v_drive_path
    return if appeal && path&.match?(V_DRIVE_PATH_MATCHER) && path&.match?(PATH_MATCHERS[appeal_type])

    errors.add(:path, COPY::INVALID_IHP_DRAFT_PATH)
  end
end
