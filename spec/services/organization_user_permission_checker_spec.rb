# frozen_string_literal: true

describe OrganizationUserPermissionChecker do
  subject(:described) { described_class.new }

  let(:organization) { create(:organization) }
  let(:user) { create(:user) }

  let!(:org_user) { create(:organizations_user, user: user, organization: organization) }
  let(:valid_permission_name) { OrganizationPermission.valid_permission_names.first }

  describe "#can_do_all?" do
    context "when permissions are enabled" do
      let!(:organization_permission) do
        create(
          :organization_permission,
          organization: organization,
          permission: valid_permission_name,
          enabled: true
        )
      end

      context "when all permissions are permitted for user" do
        let!(:org_user_permission) do
          create(
            :organization_user_permission,
            organization_permission: organization_permission,
            organizations_user: org_user,
            permitted: true
          )
        end

        it "returns true" do
          expect(
            described.can_do_all?(
              permissions: [valid_permission_name],
              organization: organization,
              user: user
            )
          ).to eq(true)
        end
      end

      context "with invalid permission name" do
        let!(:org_user_permission) do
          create(
            :organization_user_permission,
            organization_permission: organization_permission,
            organizations_user: org_user,
            permitted: true
          )
        end

        it "returns false" do
          expect(
            described.can_do_all?(
              permissions: [valid_permission_name, "not_exists_yo"],
              organization: organization,
              user: user
            )
          ).to eq(false)
        end
      end

      context "with unpermitted permission" do
        let!(:org_user_permission) do
          create(
            :organization_user_permission,
            organization_permission: organization_permission,
            organizations_user: org_user,
            permitted: false
          )
        end

        it "returns false" do
          expect(
            described.can_do_all?(
              permissions: [valid_permission_name],
              organization: organization,
              user: user
            )
          ).to eq(false)
        end
      end
    end
  end

  describe "#can?" do
    context "when permission is enabled" do
      let!(:organization_permission) do
        create(
          :organization_permission,
          organization: organization,
          permission: valid_permission_name,
          enabled: true
        )
      end

      context "when permission is permitted for user" do
        let!(:org_user_permission) do
          create(
            :organization_user_permission,
            organization_permission: organization_permission,
            organizations_user: org_user,
            permitted: true
          )
        end

        it "returns true" do
          expect(
            described.can?(permission_name: valid_permission_name, organization: organization, user: user)
          ).to eq(true)
        end
      end

      context "when permission is NOT permitted for user" do
        let!(:org_user_permission1) do
          create(
            :organization_user_permission,
            organization_permission: organization_permission,
            organizations_user: org_user,
            permitted: false
          )
        end

        it "returns false" do
          expect(
            described.can?(permission_name: valid_permission_name, organization: organization, user: user)
          ).to eq(false)
        end
      end
    end
  end
end
