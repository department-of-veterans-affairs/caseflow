# frozen_string_literal: true

describe Organization, :postgres do
  describe ".create" do
    context "when the input URL has uppercase letters and spaces" do
      let(:url_in) { "My URL_goes here" }
      let(:url_out) { "my-url-goes-here" }

      it "converts those characters before saving to the database" do
        org = Organization.create!(url: url_in, name: "Foo")
        expect(org.url).to eq(url_out)
      end
    end
  end

  describe "#user_has_access" do
    let(:org) { create(:organization) }
    let(:user) { create(:user) }

    context "when user not a member of organization" do
      it "should return false" do
        expect(org.user_has_access?(user)).to be_falsey
      end
    end

    context "when user is a member of organization" do
      before { org.add_user(user) }
      it "should return true" do
        expect(org.user_has_access?(user)).to be_truthy
      end
    end
  end

  describe ".status" do
    let(:org) { create(:organization) }

    context "upon creation" do
      it "has a default value of 'active'" do
        expect(org.status).to eq("active")
        expect(org.type).to eq(Organization.name)
      end
    end

    context "default scope" do
      it "returns only active organizations unless explicitly descoped" do
        create_list(:organization, 3)
        create_list(:organization, 3, status: "inactive")

        expect(Organization.all.size).to eq(3)
        expect(Organization.unscoped.all.size).to eq(6)
      end
    end

    context "with an invalid status" do
      subject { org.update!(status: "invalid") }

      it "fails and does not update the status_updated_at column" do
        expect { subject }.to raise_error(ArgumentError)
        expect(org.reload.status).not_to eq "invalid"
        expect(org.status_updated_at).to eq nil
      end
    end

    context "updates status_updated_at at proper time" do
      before { Timecop.freeze(Time.zone.now) }

      context "with a valid status" do
        subject { org.inactive! }

        it "succeeds and updates the status_updated_at column" do
          expect(subject).to eq true
          expect(org.reload.status).to eq Constants.ORGANIZATION_STATUSES.inactive
          expect(org.status_updated_at.to_s).to eq Time.zone.now.to_s
        end
      end
    end
  end

  describe ".users" do
    context "when organization has no members" do
      let(:org) { create(:organization) }
      it "should return an empty list" do
        expect(org.users).to eq([])
      end
    end

    context "when organization has members" do
      let(:org) { create(:organization) }
      let(:member_cnt) { 5 }
      let(:users) { create_list(:user, member_cnt) }
      before { users.each { |u| org.add_user(u) } }

      it "should return a non-empty list of members" do
        expect(org.users.length).to eq(member_cnt)
      end
    end
  end

  describe ".assignable" do
    let(:user) { create(:user) }
    let!(:organization) { create(:organization, name: "Test") }
    let!(:other_organization) { create(:organization, name: "Org") }

    context "when current task is assigned to a user" do
      let(:task) { create(:ama_task, assigned_to: user) }

      it "returns a list without that organization" do
        expect(Organization.assignable(task)).to match_array([organization, other_organization])
      end
    end

    context "when current task is assigned to an organization" do
      let(:task) { create(:ama_task, assigned_to: organization) }

      it "returns a list without that organization" do
        expect(Organization.assignable(task)).to eq([other_organization])
      end
    end

    context "when current task is assigned to a user and its parent is assigned to a user to an organization" do
      let(:parent) { create(:ama_task, assigned_to: organization) }
      let(:task) { create(:ama_task, assigned_to: user, parent: parent) }

      it "returns a list without that organization" do
        expect(Organization.assignable(task)).to eq([other_organization])
      end
    end

    context "when there is a named Organization as a subclass of Organization" do
      let(:task) { create(:ama_task, assigned_to: user) }
      before { QualityReview.singleton }

      it "should be included in the list of organizations returned by assignable" do
        expect(Organization.assignable(task).length).to eq(3)
      end
    end

    context "when organization cannot receive tasks" do
      let(:task) { create(:ama_task, assigned_to: user) }
      before { Bva.singleton }

      it "should not be included in the list of organizations returned by assignable" do
        expect(Organization.assignable(task)).to match_array([organization, other_organization])
      end
    end
  end

  describe ".user_is_admin?" do
    let(:org) { create(:organization) }
    let(:user) { create(:user) }

    context "when user is not an admin for the organization" do
      before { org.add_user(user) }
      it "should return false" do
        expect(org.user_is_admin?(user)).to eq(false)
      end
    end

    context "when user is an admin for the organization" do
      before { OrganizationsUser.make_user_admin(user, org) }
      it "should return true" do
        expect(org.user_is_admin?(user)).to eq(true)
      end
    end
  end

  describe ".next_assignee" do
    let(:org) { create(:organization) }
    let(:appeal) { nil }

    subject { org.next_assignee(appeal: appeal) }

    context "when no appeal is specified" do
      it "should return nil" do
        expect(subject).to eq(nil)
      end
    end

    context "when appeal is specified" do
      let(:appeal) { create(:appeal) }
      it "should return nil" do
        expect(subject).to eq(nil)
      end
    end
  end

  describe ".automatically_assign_to_member?" do
    let(:org) { create(:organization) }

    subject { org.automatically_assign_to_member? }

    it "should return false" do
      expect(subject).to eq(false)
    end
  end

  describe ".show_regional_office_in_queue?" do
    subject { organization.show_regional_office_in_queue? }

    context "for a generic organization" do
      let(:organization) { create(:organization) }

      it "does not show the regional office column in the queue table view" do
        expect(subject).to eq(false)
      end
    end

    context "for HearingAdmin organization" do
      let(:organization) { HearingAdmin.singleton }

      it "shows the regional office column in the queue table view" do
        expect(subject).to eq(true)
      end
    end

    context "for HearingsManagement organization" do
      let(:organization) { HearingsManagement.singleton }

      it "shows the regional office column in the queue table view" do
        expect(subject).to eq(true)
      end
    end
  end

  describe ".queue_tabs" do
    let(:org) { create(:organization) }

    it "returns the expected 4 tabs" do
      expect(org.queue_tabs.map(&:class)).to eq(
        [
          OrganizationUnassignedTasksTab,
          OrganizationAssignedTasksTab,
          OrganizationOnHoldTasksTab,
          OrganizationCompletedTasksTab
        ]
      )
    end
  end

  describe ".destroy" do
    context "when organization has members and is destroyed" do
      let(:org) { create(:organization) }
      let(:member_cnt) { 3 }
      let(:users) { create_list(:user, member_cnt) }
      before { users.each { |u| org.add_user(u) } }

      subject { org.destroy }

      it "should also destroy associated OrganizationsUser records" do
        expect(Organization.count).to eq(1)
        expect(org.users.length).to eq(member_cnt)
        expect(OrganizationsUser.count).to eq(member_cnt)

        expect(subject).to eq(org)

        expect(Organization.count).to eq(0)
        expect(OrganizationsUser.count).to eq(0)
      end
    end
  end
end
