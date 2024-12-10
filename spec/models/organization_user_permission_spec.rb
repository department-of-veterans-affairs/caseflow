# frozen_string_literal: true

describe OrganizationUserPermission do
  describe "Associations" do
    it { should belong_to(:organizations_user).required }
    it { should belong_to(:organization_permission).required }
  end

  describe "Validations" do
    it { should allow_value(%w[true false]).for(:permitted) }
    it { should_not allow_value(nil).for(:permitted) }
  end
end
