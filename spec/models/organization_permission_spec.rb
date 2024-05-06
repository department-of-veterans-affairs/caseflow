# frozen_string_literal: true

describe OrganizationPermission do
  describe "Associations" do
    it { should belong_to(:organization).required }
    it { should belong_to(:parent_permission).class_name("OrganizationPermission").optional }

    it {
      should have_many(:child_permissions).with_foreign_key("parent_permission_id")
        .class_name("OrganizationPermission").dependent(:destroy)
    }
    it { should have_many(:organization_user_permissions).dependent(:destroy) }
  end

  describe "Validations" do
    it { should validate_presence_of(:description) }
    it { should allow_value(%w[true false]).for(:enabled) }
    it { should_not allow_value(nil).for(:enabled) }

    context "permission" do
      it { should_not allow_value("bad_test").for(:permission) }

      OrganizationPermission.valid_permission_names.each do |permission_name|
        it { should allow_value(permission_name).for(:permission) }
      end
    end
  end
end
