# frozen_string_literal: true

describe User, :all_dbs do
  let(:css_id) { "TomBrady" }
  let(:session) { { "user" => { "id" => css_id, "station_id" => "310", "name" => "Tom Brady" } } }
  let(:user) { User.from_session(session) }

  before do
    Functions.client.del("System Admin")
  end

  after do
    Functions.delete_all_keys!
  end

  before do
    Fakes::AuthenticationService.user_session = nil
  end

  context ".api_user" do
    it "returns the api user" do
      expect(User.api_user.station_id).to eq "101"
      expect(User.api_user.css_id).to eq "APIUSER"
      expect(User.api_user.full_name).to eq "API User"
    end
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

  context ".find_by_vacols_username" do
    subject { described_class.find_by_vacols_username(vacols_username) }

    let(:vacols_username) { vacols_user.slogid }
    let(:vacols_user) { create(:staff) }
    let!(:caseflow_user) { create(:user, css_id: vacols_user.sdomainid) }

    before do
      CachedUser.sync_from_vacols
    end

    it "returns the User corresponding to the VACOLS account" do
      expect(subject).to eq(caseflow_user)
    end
  end

  describe "judges in VACOLS" do
    context "user is a judge" do
      let(:user) { create(:user, :with_vacols_judge_record) }
      it "distinguishes a pure judge" do
        expect(user.pure_judge_in_vacols?)
        expect(user.attorney_in_vacols?).to be false
        expect(user.acting_judge_in_vacols?).to be false
      end
    end
    context "user is an acting judge" do
      let(:user) { create(:user, :with_vacols_acting_judge_record) }
      it "distinguishes an acting judge" do
        expect(user.pure_judge_in_vacols?).to be false
        expect(user.attorney_in_vacols?)
        expect(user.acting_judge_in_vacols?)
      end
    end
    context "user is a pure attorney" do
      let(:user) { create(:user, :with_vacols_attorney_record) }
      it "distinguishes an acting attorney" do
        expect(user.pure_judge_in_vacols?).to be false
        expect(user.attorney_in_vacols?)
        expect(user.acting_judge_in_vacols?).to be false
      end
    end
  end

  context ".batch_find_by_css_id_or_create_with_default_station_id" do
    subject { User.batch_find_by_css_id_or_create_with_default_station_id(css_ids) }

    context "when the input list of CSS IDs includes a lowercase CSS ID" do
      let(:lowercase_css_id) { Generators::Random.from_set(("a".."z").to_a, 16) }
      let(:css_ids) { [lowercase_css_id] }

      context "when the User record for the lowercase CSS ID does not yet exist in the database" do
        it "returns the newly created User record for that CSS ID" do
          expect(subject.length).to eq(1)
        end
      end

      context "when the User record for the lowercase CSS ID already exists in the database" do
        before { User.create(css_id: lowercase_css_id, station_id: User::BOARD_STATION_ID) }
        it "returns the existing User record for that CSS ID" do
          expect(subject.length).to eq(1)
        end
      end
    end
  end

  context ".list_hearing_coordinators" do
    let!(:users) { create_list(:user, 5) }
    let!(:other_users) { create_list(:user, 5) }
    before do
      users.each do |user|
        HearingsManagement.singleton.add_user(user)
      end
    end
    it "returns a list of hearing coordinators" do
      expect(User.list_hearing_coordinators).to match_array(users)
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
        "name" => "Tom Brady",
        "status" => Constants.USER_STATUSES.active,
        "status_updated_at" => nil
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

  context "scope with_role" do
    subject { User.with_role("VSO") }
    let!(:user2) { create(:user, roles: ["VSO"]) }
    before { user.update(roles: ["System Admin", "VSO", "Certify Appeal"]) }
    it "returns all users with role" do
      expect(subject).to match_array [user, user2]
    end
  end

  context "#job_title" do
    let!(:user) { create(:user, css_id: "BVAAABSHIRE", station_id: "101") }
    subject { user.job_title }

    context "when user.job_title is Senior Veterans Service Representative" do
      it "is expected the job_title is Senior Veterans Service Representative" do
        expect(subject).to eq("Senior Veterans Service Representative")
      end
      it "is expected that user.can_intake_decision_reviews? is false" do
        expect(user.can_intake_decision_reviews?).to be_falsey
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
    let(:user) { create(:user) }
    let!(:staff) { create(:staff, :attorney_role, user: user) }

    subject { user.selectable_organizations }

    context "when user is not a judge in vacols and does not have a judge team" do
      it "does not return assigned cases link for judge" do
        is_expected.to be_empty
      end
    end

    context "when user is a judge in vacols" do
      let!(:staff) { create(:staff, :attorney_judge_role, user: user) }

      it "returns assigned cases link for judge" do
        is_expected.to include(
          name: "Assign #{user.css_id}",
          url: format("/queue/%<id>s/assign", id: user.css_id)
        )
      end
    end

    context "when user has a judge team" do
      before { JudgeTeam.create_for_judge(user) }

      it "returns assigned cases link for judge" do
        user.reload
        is_expected.to include(
          name: "Assign #{user.css_id}",
          url: format("/queue/%<id>s/assign", id: user.css_id)
        )
      end
    end

    context "when the user is a judge team admin" do
      let(:judge_team) { JudgeTeam.create_for_judge(user) }
      let!(:judge) { judge_team.admin }

      before do
        allow(JudgeTeam).to receive(:for_judge).with(judge).and_return(nil)
        allow(judge).to receive(:judge_in_vacols?).and_return(false)
      end

      it "does not return assigned cases link for judge" do
        is_expected.to be_empty
      end

      context "when special case movement is enabled" do
        before { FeatureToggle.enable!(:judge_admin_scm) }
        after { FeatureToggle.disable!(:judge_admin_scm) }

        it "returns assigned cases link for judge" do
          is_expected.to include(
            name: "Assign #{judge.css_id}",
            url: format("/queue/%<id>s/assign", id: judge.css_id)
          )
          is_expected.not_to include(
            name: "Assign #{user.css_id}",
            url: format("/queue/%<id>s/assign", id: user.id)
          )
        end
      end
    end
  end

  context "#member_of_organization?" do
    let(:org) { create(:organization) }
    let(:user) { create(:user) }

    subject { user.member_of_organization?(org) }

    context "when the organization does not exist" do
      let(:org) { nil }
      it "returns false" do
        expect(subject).to eq(false)
      end
    end

    context "when the current user is not a member of the organization" do
      it "returns false" do
        expect(subject).to eq(false)
      end
    end

    context "when the user is a member of the organization" do
      before { org.add_user(user) }
      it "returns true" do
        expect(subject).to eq(true)
      end
    end
  end

  context "#when BGS data is setup" do
    let(:participant_id) { "123456" }
    let(:vso_participant_id) { Fakes::BGSServicePOA::VIETNAM_VETERANS_VSO_PARTICIPANT_ID }
    let(:vso_participant_ids) { Fakes::BGSServicePOA.default_vsos_poas }

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

    context "when user is a BVA admin" do
      before { Bva.singleton.add_user(user) }
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
      let!(:task) { create(:task, appeal: appeal, assigned_to: user) }

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

      it "resets pg_user_id when it is not found" do
        user = create(:user, css_id: css_id)
        expect(User).to receive(:find_by_css_id).and_call_original
        session["user"]["pg_user_id"] = user.id + 1000 # integer not found
        expect(subject).to eq user
        expect(session["user"]["pg_user_id"]).to eq user.id
      end

      it "updates last_login_at if it was more than 5 minutes ago" do
        user = create(:user, last_login_at: Time.zone.now - 10.minutes)
        session["user"]["pg_user_id"] = user.id
        expect(subject.last_login_at).to be_within(1.second).of(Time.zone.now)
      end

      it "does not update last_login_at if it was less than 5 minutes ago" do
        user = create(:user, last_login_at: Time.zone.now - 1.minute)
        session["user"]["pg_user_id"] = user.id
        expect(subject.last_login_at).to be_within(1.second).of(Time.zone.now - 1.minute)
      end

      describe "check SQL queries are only called when needed" do
        before do
          Timecop.freeze(Time.zone.now - time_ago) do
            user = create(:user)
            session["user"]["pg_user_id"] = user.id
            User.from_session(session)
          end
        end
        context "last_login_at was more than 5 minutes ago" do
          let(:time_ago) { 6.minutes }

          it "executes SQL UPDATE" do
            query_data = SqlTracker.track do
              expect(subject).to eq user
            end
            update_queries = query_data.values.select { |o| o[:sql].start_with?("UPDATE \"users\"") }
            expect(update_queries.pluck(:count).max).to eq 1
          end
        end
        context "last_login_at was less than 5 minutes ago" do
          let(:time_ago) { 4.minutes }

          it "does not execute SQL UPDATE" do
            query_data = SqlTracker.track do
              expect(subject).to eq user
            end
            update_queries = query_data.values.select { |o| o[:sql].start_with?("UPDATE \"users\"") }
            expect(update_queries).to be_empty
          end
        end
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
      before { org.add_user(user) }
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
        member_orgs.each { |o| o.add_user(user) }
        admin_orgs.each { |o| OrganizationsUser.make_user_admin(user, o) }
      end
      it "should return a list of all teams user is an admin for" do
        expect(user.administered_teams).to include(*admin_orgs)
      end
    end
  end

  describe ".organization_queue_user?" do
    let(:user) { create(:user) }

    subject { user.organization_queue_user? }

    context "when the current user is not a member of any organizations" do
      it "returns false" do
        expect(subject).to eq(false)
      end
    end

    context "when the user is a member of some organizations" do
      before { create(:organization).add_user(user) }
      it "returns true" do
        expect(subject).to eq(true)
      end
    end
  end

  describe ".can_withdraw_issues?" do
    let(:user) { create(:user) }

    subject { user.can_withdraw_issues? }

    context "when the current user is not a member of Case-review Organization" do
      it "returns false" do
        expect(subject).to eq(false)
      end
      context "when the user is at a regional office" do
        before { allow(user).to receive(:regional_office).and_return("RO85") }
        it "returns true" do
          expect(subject).to eq(true)
        end
      end
    end

    context "when the user is a member of Case review Organization" do
      before { CaseReview.singleton.add_user(user) }
      it "returns true" do
        expect(subject).to eq(true)
      end
    end
  end

  describe "#can_intake_appeals?" do
    let(:user) { create(:user) }

    subject { user.can_intake_appeals? }

    it { is_expected.to be_falsey }

    context "when the user is a member of the BVA Intake Team" do
      before { BvaIntake.singleton.add_user(user) }

      it { is_expected.to be_truthy }
    end
  end

  describe "when the status is updated" do
    let(:user) { create(:user) }

    subject { user.update_status!(status) }

    before { Timecop.freeze(Time.zone.now) }

    context "with an invalid status" do
      let(:status) { "invalid" }

      it "fails and does not update the status_updated_at column" do
        expect { subject }.to raise_error(ArgumentError)
        expect(user.reload.status).not_to eq status
        expect(user.status_updated_at).to eq nil
      end
    end

    context "with a valid status" do
      let(:status) { Constants.USER_STATUSES.inactive }

      it "succeeds and updates the status_updated_at column" do
        expect(subject).to eq true
        expect(user.reload.status).to eq status
        expect(user.status_updated_at.to_s).to eq Time.zone.now.to_s
      end

      context "when the user is a judge with a JudgeTeam" do
        let(:judge_team) { create(:judge_team, :has_judge_team_lead_as_admin) }
        let(:user) { judge_team.judge }

        before { allow(user).to receive(:judge_in_vacols?).and_return(true) }

        context "when marking the user inactive" do
          it "marks their JudgeTeam as inactive" do
            expect(subject).to eq true
            expect(judge_team.reload.status).to eq status
            expect(judge_team.judge).to eq user
          end
        end

        context "when making an inactive user active" do
          let(:status) { Constants.USER_STATUSES.active }

          before { user.update_status!(Constants.USER_STATUSES.inactive) }

          it "marks their JudgeTeam as active" do
            expect(judge_team.reload.status).to eq Constants.USER_STATUSES.inactive
            expect(subject).to eq true
            expect(judge_team.reload.status).to eq status
          end
        end
      end

      context "when the user is a member of many orgs" do
        let(:judge_team) { JudgeTeam.create_for_judge(create(:user)) }
        let(:other_orgs) { [Colocated.singleton, create(:organization)] }

        before { other_orgs.each { |org| org.add_user(user) } }

        context "when marking the user inactive" do
          before { judge_team.add_user(user) }

          it "removes users from all organizations, including JudgeTeam" do
            expect(user.organizations.size).to eq 3
            expect(user.selectable_organizations.length).to eq 2
            expect(subject).to eq true
            expect(user.reload.status).to eq status
            expect(user.status_updated_at.to_s).to eq Time.zone.now.to_s
            expect(user.organizations.size).to eq 0
            expect(user.selectable_organizations.length).to eq 0
          end
        end

        context "when marking the admin inactive", skip: "flaky test" do
          before do
            OrganizationsUser.make_user_admin(user, judge_team)
            allow(user).to receive(:judge_in_vacols?).and_return(false)
          end

          it "removes admin from all organizations, including JudgeTeam" do
            if FeatureToggle.enabled?(:judge_admin_scm)
              expect(judge_team.judge).not_to eq user
              expect(user.selectable_organizations.length).to eq 3
            else
              expect(user.selectable_organizations.length).to eq 2
            end

            expect(judge_team.admin).to eq user
            expect(user.organizations.size).to eq 3
            expect(subject).to eq true
            expect(user.reload.status).to eq status
            expect(user.status_updated_at.to_s).to eq Time.zone.now.to_s
            expect(user.organizations.size).to eq 0
            expect(user.selectable_organizations.length).to eq 0
          end
        end

        context "when marking the judge inactive" do
          let(:judge_team) { JudgeTeam.create_for_judge(user) }
          before { allow(user).to receive(:judge_in_vacols?).and_return(true) }

          it "removes judge from all orgs except their own JudgeTeam" do
            expect(user.judge?)
            expect(judge_team.judge).to eq user
            expect(user.organizations.size).to eq 3
            expect(user.selectable_organizations.length).to eq 3
            expect(user.update_status!(status)).to eq true
            expect(user.reload.status).to eq status
            expect(user.status_updated_at.to_s).to eq Time.zone.now.to_s
            expect(judge_team.judge).to eq user
            expect(user.organizations.size).to eq 0 # 0 since judge_team is inactive
            # Every judge in vacols should be able to see their assign page, even if they don't have a judge team
            expect(user.selectable_organizations.length).to eq 1
          end

          context "when judge is a non-admin in another JudgeTeam" do
            let(:judge_team2) { JudgeTeam.create_for_judge(create(:user)) }
            before { allow(user).to receive(:judge_in_vacols?).and_return(true) }
            before { judge_team2.add_user(user) }

            it "removes judge from all orgs (including JudgeTeams) except their own JudgeTeam" do
              expect(user.judge?)
              expect(judge_team.judge).to eq user
              expect(user.organizations.size).to eq 4
              expect(user.selectable_organizations.length).to eq 3
              expect(user.update_status!(status)).to eq true
              expect(user.reload.status).to eq status
              expect(user.status_updated_at.to_s).to eq Time.zone.now.to_s
              expect(judge_team.judge).to eq user
              expect(user.organizations.size).to eq 0 # 0 since judge_team is inactive
              # Every judge in vacols should be able to see their assign page, even if they don't have a judge team
              expect(user.selectable_organizations.length).to eq 1
            end
          end
        end

        context "when marking the user active" do
          let(:user) { create(:user, status: Constants.USER_STATUSES.inactive) }
          let(:status) { Constants.USER_STATUSES.active }

          it "does not remove the user from any organizations" do
            expect(user.selectable_organizations.length).to eq 2
            expect(subject).to eq true
            expect(user.reload.status).to eq status
            expect(user.status_updated_at.to_s).to eq Time.zone.now.to_s
            expect(user.selectable_organizations.length).to eq 2
            expect(user.selectable_organizations).to include Colocated.singleton
          end
        end
      end
    end
  end
end
