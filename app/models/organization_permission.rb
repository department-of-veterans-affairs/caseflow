# frozen_string_literal: true

class OrganizationPermission < CaseflowRecord
  belongs_to :organization, optional: false

  belongs_to :parent_permission, class_name: "OrganizationPermission", optional: true
  has_many :child_permissions, class_name: "OrganizationPermission", foreign_key: "parent_permission_id",
                               dependent: :destroy

  has_many :organization_user_permissions, dependent: :destroy

  validates :description, presence: true
  validates :enabled, inclusion: [true, false]

  validate :valid_permission

  def valid_permission
    errors.add(:permission, "Invalid permission") unless
    self.class.valid_permission_names.include?(permission)
  end

  class << self
    def valid_permission_names
      Constants.ORGANIZATION_PERMISSIONS.to_h.values
    end

    def auto_assign(organization)
      find_by(organization: organization, permission: Constants.ORGANIZATION_PERMISSIONS.auto_assign)
    end

    def receive_nod_mail(organization)
      find_by(organization: organization, permission: Constants.ORGANIZATION_PERMISSIONS.receive_nod_mail)
    end
  end
end
