require "rails_helper"

User.authentication_service = Fakes::AuthenticationService

describe User do
  let(:session) { { "user" => { "id" => "123", "station_id" => "310" } } }
  let(:user) { User.from_session(session) }

  before(:all) do
    User.appeal_repository = Fakes::AppealRepository
    Functions.client.del("System Admin")
  end

  after(:all) do
    Functions.delete_all_keys!
  end

  before do
    Fakes::AuthenticationService.user_session = nil
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
      it { is_expected.to eq("Shaner (RO77)") }
    end

    context "when just username is set" do
      before { session["user"]["id"] = "Shaner" }
      it { is_expected.to eq("Shaner") }
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
      before { Functions.grant!("Do the thing", users: ["123"]) }
      it { is_expected.to be_truthy }
    end

    context "when roles contains the thing but user is denied" do
      before { session["user"]["roles"] = ["Do the thing"] }
      before { Functions.deny!("Do the thing", users: ["123"]) }
      it { is_expected.to be_falsey }
    end

    context "when system admin and roles don't contain the thing" do
      before { Functions.grant!("System Admin", users: ["123"]) }
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
      before { Functions.grant!("System Admin", users: ["123"]) }
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

    let(:appeal) { Generators::Appeal.create }

    before do
      User.appeal_repository = Fakes::AppealRepository
    end

    it "returns empty array when no cases are assigned" do
      Fakes::AppealRepository.appeal_records = []
      is_expected.to be_empty
    end

    it "returns appeal assigned to user" do
      Fakes::AppealRepository.appeal_records = [appeal]
      is_expected.to match_array([appeal])
    end
  end

  context "#current_case_assignments_with_views" do
    subject { user.current_case_assignments_with_views[0] }

    let(:appeal) { Generators::Appeal.create }

    before do
      Fakes::AppealRepository.appeal_records = [appeal]
    end

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
        AppealView.create(user_id: user.id, appeal_id: appeal.id)
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
      end

      it do
        is_expected.to be_an_instance_of(User)
        expect(subject.roles).to eq(["Do the thing"])
        expect(subject.regional_office).to eq("283")
        expect(subject.full_name).to eq("Anne Merica")
      end

      it "persists user to DB" do
        expect(User.find(subject.id)).to be_truthy
      end
    end

    context "returns nil when no user in session" do
      before { session["user"] = nil }
      it { is_expected.to be_nil }
    end
  end

  context ".create_from_vacols" do
    subject { Judge.create_from_vacols(css_id: "VACOFODR", station_id: "283", full_name: "Fred Odraine") }

    it "should create a user record" do
      expect(subject.class).to eq User
      expect(subject.css_id).to eq "VACOFODR"
      expect(subject.station_id).to eq "283"
      expect(subject.full_name).to eq "Fred Odraine"
    end
  end

  context ".current_task" do
    class FakeTask < Task; end
    class AnotherFakeTask < Task; end

    subject { user.current_task(FakeTask) }

    context "when there is no current task of the task class" do
      let(:another_user) { User.create!(station_id: "ABC", css_id: "ROBBY") }

      let!(:task_assigned_to_another_user) do
        FakeTask.create!(
          user: another_user,
          aasm_state: :unassigned,
          appeal: Generators::Appeal.create
        )
      end

      let!(:task_of_another_type) do
        AnotherFakeTask.create!(
          user: user,
          aasm_state: :unassigned,
          appeal: Generators::Appeal.create
        )
      end

      let!(:inactive_task) do
        FakeTask.create!(
          user: user,
          aasm_state: :completed,
          appeal: Generators::Appeal.create
        )
      end

      it { is_expected.to be_nil }
    end

    context "when user has a current task" do
      let!(:current_task) do
        FakeTask.create!(
          user: user,
          aasm_state: :started,
          appeal: Generators::Appeal.create,
          prepared_at: Date.yesterday
        )
      end

      it { is_expected.to eq(current_task) }
    end
  end
end
