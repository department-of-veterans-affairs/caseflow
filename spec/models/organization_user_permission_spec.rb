# frozen_string_literal: true

describe OrganizationUserPermission do
  describe "Associations" do
    it { should belong_to(:organizations_user).required }
    it { should belong_to(:organization_permission).required }
  end

  describe "Validations" do
    it { should validate_presence_of(:permitted) }
  end
end
