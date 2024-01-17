# frozen_string_literal: true

class OrganizationPermission < CaseflowRecord
  belongs_to :organization, required: true

  belongs_to :parent_permission, class_name: "OrganizationPermission", optional: true
  has_many :child_permissions, class_name: "OrganizationPermission", foreign_key: "parent_permission_id", dependent: :destroy

  validates_presence_of :permission
  validates_presence_of :description
  validates_presence_of :enabled
end
