# frozen_string_literal: true

describe OrganizationPermission do
  describe "Associations" do
    it { should belong_to(:organization).required }
    it { should belong_to(:parent_permission).class_name("OrganizationPermission").optional }

    it {
      should have_many(:child_permissions).with_foreign_key("parent_permission_id")
        .class_name("OrganizationPermission").dependent(:destroy)
    }
  end

  describe "Validations" do
    it { should validate_presence_of(:permission) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:enabled) }
  end
end
