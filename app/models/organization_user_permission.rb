# frozen_string_literal: true

class OrganizationUserPermission < CaseflowRecord
  belongs_to :organizations_user, optional: false
  belongs_to :organization_permission, optional: false

  validates :permitted, inclusion: [true, false]
end
