# frozen_string_literal: true

class OrganizationUserPermission < CaseflowRecord
  belongs_to :organizations_user, required: true
  belongs_to :organization_permission, required: true

  validates_presence_of :permitted
end
