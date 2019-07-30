# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe OrganizationsUser, :postgres do
  let(:organization) { FactoryBot.create(:organization) }
  let(:user) { FactoryBot.create(:user) }

  describe ".remove_admin_rights_from_user" do
    subject { OrganizationsUser.remove_admin_rights_from_user(user, organization) }

    context "when user is not a member of the organization" do
      it "does not add the user to the organization" do
        expect(subject).to eq(nil)
        expect(organization.users.count).to eq(0)
      end
    end

    context "when user a member of the organization" do
      before { OrganizationsUser.add_user_to_organization(user, organization) }

      it "does nothing" do
        expect(subject).to eq(true)
        expect(organization.admins.count).to eq(0)
      end
    end

    context "when user an admin of the organization" do
      before { OrganizationsUser.make_user_admin(user, organization) }

      it "removes admin rights from the user" do
        expect(organization.admins.count).to eq(1)
        expect(subject).to eq(true)
        expect(organization.admins.count).to eq(0)
      end
    end
  end
end
