# frozen_string_literal: true

require "rails_helper"

describe User do
  let(:css_id) { "TomBrady" }
  let(:session) { { "user" => { "id" => css_id, "station_id" => "310", "name" => "Tom Brady" } } }
  let(:user) { User.from_session(session) }

  before(:all) do
    Functions.client.del("System Admin")
  end

  after(:all) do
    Functions.delete_all_keys!
  end

  before do
    Fakes::AuthenticationService.user_session = nil
  end

  context ".find_by_css_id" do
    let!(:user) { create(:user, css_id: "FOOBAR") }

    it "searches case insensitively" do
      expect(User.find_by_css_id("fooBaR")).to eq(user)
    end
  end

  context ".find_by_css_id_or_create_with_default_station_id" do
    subject { User.find_by_css_id_or_create_with_default_station_id(css_id) }

    it "forces the css id to UPCASE" do
      expect(css_id.upcase).to_not eq(css_id)
      expect(subject.css_id).to eq(css_id.upcase)
    end
  end

  context "#regional_office" do
    context "when RO can't be determined using station_id" do
      subject { user.regional_office }
      before { session["user"]["station_id"] = "405" }
      it { is_expected.to be_nil }
    end

    context "when RO can be determined using station_id" do
      subject { user.regional_office }
      before { session["user"]["station_id"] = "301" }
      it { is_expected.to eq("RO01") }
    end
  end

  context "#to_session_hash" do
    subject { user.to_session_hash }

    let(:result) do
      {
        "id" => css_id.upcase,
        "station_id" => "310",
        "css_id" => css_id.upcase,
        "pg_user_id" => user.id,
        "email" => nil,
        "roles" => [],
        "efolder_documents_fetched_at" => nil,
        "selected_regional_office" => nil,
        :display_name => css_id.upcase,
        "name" => "Tom Brady"
      }
    end

    it { is_expected.to eq result }
  end

  context "#roles" do
    subject { user.roles }

    context "when roles is nil" do
      before { user.roles = nil }
      it { is_expected.to eq([]) }
    end

    context "when roles has non-aliased roles" do
      before { user.roles = ["System Admin", "Certify Appeal"] }
      it { is_expected.to eq(["System Admin", "Certify Appeal"]) }
    end

    context "when persisted to database" do
      before { user.update(roles: ["System Admin"]) }
      it "can read from saved attributes" do
        expect(user.read_attribute(:roles)).to eq(["System Admin"])
      end
    end

    context "when has a role alias" do
      before { user.roles = ["Manage Claims Establishme"] }
      it "is expected to return the aliases as well" do
        expect(subject).to include("Manage Claim Establishment", "Manage Claims Establishme")
      end
    end
  end

  context "#timezone" do
    context "when ro is set" do
      subject { user.timezone }
      before { user.regional_office = "RO84" }
      it { is_expected.to eq("America/New_York") }
    end

    context "when ro isn't set" do
      subject { user.timezone }
      before { user.regional_office = nil }
      it { is_expected.to eq("America/Chicago") }
    end
  end

  context "CSUM/CSEM users with 'System Admin' function" do
    before { user.roles = ["System Admin"] }
    before { Functions.client.del("System Admin") }

    it "are not admins" do
      expect(user.admin?).to be_falsey
    end
  end

  context "#display_name" do
    subject { user.display_name }

    context "when username and RO are both set" do
      before do
        session["user"]["id"] = "Shaner"
        user.regional_office = "RO77"
      end
      it { is_expected.to eq("SHANER (RO77)") }
    end

    context "when just username is set" do
      before { session["user"]["id"] = "Shaner" }
      it { is_expected.to eq("SHANER") }
    end
  end

  context "#can?" do
    subject { user.can?("Do the thing") }
    before { Functions.client.del("System Admin") }

    context "when roles are nil" do
      before { session["user"]["roles"] = nil }
      it { is_expected.to be_falsey }
    end

    context "when roles don't contain the thing" do
      before { session["user"]["roles"] = ["Do the other thing!"] }
      it { is_expected.to be_falsey }
    end

    context "when roles contains the thing" do
      before { session["user"]["roles"] = ["Do the thing"] }
      it { is_expected.to be_truthy }
    end

    context "when roles don't contain the thing but user is granted the function" do
      before { session["user"]["roles"] = ["Do the other thing!"] }
      before { Functions.grant!("Do the thing", users: [css_id.upcase]) }
      it { is_expected.to be_truthy }
    end

    context "when roles contains the thing but user is denied" do
      before { session["user"]["roles"] = ["Do the thing"] }
      before { Functions.deny!("Do the thing", users: [css_id.upcase]) }
      it { is_expected.to be_falsey }
    end

    context "when system admin and roles don't contain the thing" do
      before { Functions.grant!("System Admin", users: [css_id.upcase]) }
      before { session["user"]["roles"] = ["Do the other thing"] }
      it { is_expected.to be_truthy }
    end
  end

  context "#admin?" do
    subject { user.admin? }
    before { session["user"]["roles"] = nil }
    before { Functions.client.del("System Admin") }

    context "when user with roles that are nil" do
      it { is_expected.to be_falsey }
    end

    context "when user with roles that don't contain admin" do
      before { session["user"]["roles"] = ["Do the other thing!"] }
      it { is_expected.to be_falsey }
    end

    context "when user with roles that contain admin" do
      before { Functions.grant!("System Admin", users: [css_id.upcase]) }
      it { is_expected.to be_truthy }
    end
  end

  context "#authenticated?" do
    subject { user.authenticated? }
    before { session[:username] = "USER" }

    context "when regional_office set" do
      before { user.regional_office = "RO77" }
      it { is_expected.to be_truthy }
    end

    context "when regional_office isn't set" do
      before { user.regional_office = nil }
      it { is_expected.to be_falsy }
    end
  end

  context "#authenticate" do
    subject { user.regional_office = "rO21" }

    context "when user enters lowercase RO" do
      it "sets regional_office in the session" do
        is_expected.to be_truthy
        expect(user.regional_office).to eq("RO21")
      end
    end
  end

  context "#current_case_assignments" do
    subject { user.current_case_assignments }

    it "returns empty array when no cases are assigned" do
      is_expected.to be_empty
    end

    context "when case is assigned to a user" do
      let!(:appeal) { create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user)) }

      it "returns appeal assigned to user" do
        is_expected.to match_array([appeal])
      end
    end
  end

  context "#selectable_organizations" do
    let(:judge) { FactoryBot.create :user }
    let!(:judgeteam) { JudgeTeam.create_for_judge(judge) }

    subject { user.selectable_organizations }

    context "when user is the team's judge" do
      let(:user) { judge }

      it "includes judge teams from the organization list" do
        is_expected.to include(
          id: judgeteam.id,
          name: "Assign",
          url: format("queue/%<id>s/assign", id: user.id)
        )
        expect(user.organizations).to include judgeteam
      end
    end

    context "when user is not the team's judge" do
      before do
        OrganizationsUser.add_user_to_organization(user, judgeteam)
      end

      it "excludes judge teams from the organization list" do
        is_expected.to be_empty
        expect(user.organizations).to include judgeteam
      end
    end
  end

  context "#when BGS data is setup" do
    let(:participant_id) { "123456" }
    let(:vso_participant_id) { "123456" }

    let(:vso_participant_ids) do
      [
        {
          legacy_poa_cd: "070",
          nm: "VIETNAM VETERANS OF AMERICA",
          org_type_nm: "POA National Organization",
          ptcpnt_id: vso_participant_id
        },
        {
          legacy_poa_cd: "071",
          nm: "PARALYZED VETERANS OF AMERICA, INC.",
          org_type_nm: "POA National Organization",
          ptcpnt_id: "2452383"
        }
      ]
    end

    before do
      stub_const("BGSService", ExternalApi::BGSService)
      RequestStore[:current_user] = user

      allow_any_instance_of(BGS::SecurityWebService).to receive(:find_participant_id)
        .with(css_id: user.css_id, station_id: user.station_id).and_return(participant_id)
      allow_any_instance_of(BGS::OrgWebService).to receive(:find_poas_by_ptcpnt_id)
        .with(participant_id).and_return(vso_participant_ids)
    end

    context "#participant_id" do
      it "returns the users participant id" do
        expect(user.participant_id).to eq(participant_id)
      end
    end

    context "#vsos_user_represents" do
      it "returns a list of VSOs" do
        expect(user.vsos_user_represents.first[:participant_id]).to eq(vso_participant_id)
      end
    end
  end

  context "#administer_org_users?" do
    subject { user.administer_org_users? }
    before { session["user"]["roles"] = nil }
    before { Functions.client.del("System Admin") }

    context "when user with roles that are nil" do
      it { is_expected.to be_falsey }
    end

    context "when user with roles that don't contain admin" do
      before { session["user"]["roles"] = ["Do the other thing!"] }
      it { is_expected.to be_falsey }
    end

    context "when user with roles that contain admin" do
      before { Functions.grant!("System Admin", users: [css_id.upcase]) }
      it { is_expected.to be_truthy }
    end

    context "when user with grant that contain Admin Intake" do
      before { Functions.grant!("Admin Intake", users: [css_id.upcase]) }
      it { is_expected.to be_truthy }
    end

    context "when user with roles that contain Admin Intake" do
      before { session["user"]["roles"] = ["Admin Intake"] }
      it { is_expected.to be_truthy }
    end
  end

  context "#appeal_has_task_assigned_to_user?" do
    context "when legacy appeal" do
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

      it "when fail_if_no_access_to_legacy_task! returns true, should return true" do
        expect(UserRepository).to receive(:fail_if_no_access_to_task!).once.and_return(true)
        expect(user.appeal_has_task_assigned_to_user?(appeal)).to eq(true)
      end
    end

    context "when appeal has task assigned to user" do
      let(:appeal) { create(:appeal) }
      let!(:task) { create(:task, type: "GenericTask", appeal: appeal, assigned_to: user) }

      it "should return true" do
        expect(user.appeal_has_task_assigned_to_user?(appeal)).to eq(true)
      end
    end

    context "when appeal doesn't have task assigned to user" do
      let(:appeal) { create(:appeal) }

      it "should return false" do
        expect(user.appeal_has_task_assigned_to_user?(appeal)).to eq(false)
      end
    end
  end

  context "#current_case_assignments_with_views" do
    subject { user.current_case_assignments_with_views[0] }

    let!(:appeal) { create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user)) }

    it "returns nil when no cases have been viewed" do
      is_expected.to include(
        "vbms_id" => appeal.vbms_id,
        "vacols_id" => appeal.vacols_id,
        "veteran_full_name" => appeal.veteran_full_name,
        "viewed" => nil
      )
    end

    context "has hash with view" do
      before do
        AppealView.create(user_id: user.id, appeal: appeal)
      end

      it do
        is_expected.to include(
          "vbms_id" => appeal.vbms_id,
          "vacols_id" => appeal.vacols_id,
          "veteran_full_name" => appeal.veteran_full_name,
          "viewed" => true
        )
      end
    end
  end

  context ".from_session" do
    subject { User.from_session(session) }
    context "gets a user object from a session" do
      before do
        session["user"]["roles"] = ["Do the thing"]
        session[:regional_office] = "283"
        session["user"]["name"] = "Anne Merica"
        Timecop.freeze(Time.zone.now)
      end

      after do
        Timecop.return
      end

      it do
        expect(User).to receive(:find_by_css_id)
        is_expected.to be_an_instance_of(User)
        expect(subject.roles).to eq(["Do the thing"])
        expect(subject.regional_office).to eq("283")
        expect(subject.full_name).to eq("Anne Merica")
        expect(subject.css_id).to eq("TOMBRADY")
        expect(subject.last_login_at).to eq(Time.zone.now)
      end

      it "persists user to DB" do
        expect(User.find(subject.id)).to be_truthy
      end

      it "searches by user id when it is in session" do
        user = create(:user)
        expect(User).to_not receive(:find_by_css_id)
        session["user"]["pg_user_id"] = user.id
        expect(subject).to eq user
      end
    end

    context "returns nil when no user in session" do
      before { session["user"] = nil }
      it { is_expected.to be_nil }
    end

    context "user exists with different station_id" do
      let(:station_id) { "123" }
      let(:new_station_id) { "456" }
      let!(:existing_user) { create(:user, css_id: "foobar", station_id: station_id) }

      before do
        session["user"]["station_id"] = new_station_id
        session["user"]["id"] = existing_user.css_id
      end

      it "updates station_id from session" do
        subject

        expect(existing_user.reload.station_id).to eq(new_station_id)
      end
    end
  end

  context ".current_task" do
    class FakeTask < Dispatch::Task; end
    class AnotherFakeTask < Dispatch::Task; end

    subject { user.current_task(FakeTask) }

    context "when there is no current task of the task class" do
      let(:another_user) { User.create!(station_id: "ABC", css_id: "ROBBY") }

      let!(:task_assigned_to_another_user) do
        FakeTask.create!(
          user: another_user,
          aasm_state: :unassigned,
          appeal: create(:legacy_appeal, vacols_case: create(:case))
        )
      end

      let!(:task_of_another_type) do
        AnotherFakeTask.create!(
          user: user,
          aasm_state: :unassigned,
          appeal: create(:legacy_appeal, vacols_case: create(:case))
        )
      end

      let!(:inactive_task) do
        FakeTask.create!(
          user: user,
          aasm_state: :completed,
          appeal: create(:legacy_appeal, vacols_case: create(:case))
        )
      end

      it { is_expected.to be_nil }
    end

    context "when user has a current task" do
      let!(:current_task) do
        FakeTask.create!(
          user: user,
          aasm_state: :started,
          appeal: create(:legacy_appeal, vacols_case: create(:case)),
          prepared_at: Date.yesterday
        )
      end

      it { is_expected.to eq(current_task) }
    end
  end

  describe ".administered_teams" do
    let(:org) { create(:organization) }
    let(:user) { create(:user) }

    context "when user belongs to one organization but is not an admin" do
      before { OrganizationsUser.add_user_to_organization(user, org) }
      it "should return an empty list" do
        expect(user.administered_teams).to eq([])
      end
    end

    context "when user is an admin of one organization" do
      before { OrganizationsUser.make_user_admin(user, org) }
      it "should return a list that contains the single organization" do
        expect(user.administered_teams).to eq([org])
      end
    end

    context "when user belongs to several organizations and is an admin of several different organizations" do
      let(:member_orgs) { create_list(:organization, 5) }
      let(:admin_orgs) { create_list(:organization, 3) }

      before do
        member_orgs.each { |o| OrganizationsUser.add_user_to_organization(user, o) }
        admin_orgs.each { |o| OrganizationsUser.make_user_admin(user, o) }
      end
      it "should return a list of all teams user is an admin for" do
        expect(user.administered_teams).to include(*admin_orgs)
      end
    end
  end

  describe ".organization_queue_user?" do
    let(:user) { FactoryBot.create(:user) }

    subject { user.organization_queue_user? }

    context "when the current user is not a member of any organizations" do
      it "returns false" do
        expect(subject).to eq(false)
      end
    end

    context "when the user is a member of some organizations" do
      before { OrganizationsUser.add_user_to_organization(user, FactoryBot.create(:organization)) }
      it "returns true" do
        expect(subject).to eq(true)
      end
    end
  end
end
