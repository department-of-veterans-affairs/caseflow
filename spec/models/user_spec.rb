User.authentication_service = Fakes::AuthenticationService

describe User do
  let(:session) { { "user" => { "id" => "123", "station_id" => "456" } } }
  let(:user) { User.from_session(session) }
  before { Fakes::AuthenticationService.user_session = nil }

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

  context "#timezone" do
    context "when ro is set" do
      subject { user.timezone }
      before { user.regional_office = "RO26" }
      it { is_expected.to eq("America/Indiana/Indianapolis") }
    end

    context "when ro isn't set" do
      subject { user.timezone }
      before { user.regional_office = nil }
      it { is_expected.to eq("America/Chicago") }
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
    subject { user.authenticate(regional_office: "rO21", password: password) }
    before do
      Fakes::AuthenticationService.vacols_regional_offices = {
        "RO21" => "pinkpowerranger" }
    end

    context "when user enters lowercase RO" do
      let(:password) { "pinkpowerranger" }

      it "sets regional_office in the session" do
        is_expected.to be_truthy
        expect(user.regional_office).to eq("RO21")
      end
    end
  end

  context "#authenticate" do
    subject { user.authenticate(regional_office: "RO21", password: password) }
    before do
      Fakes::AuthenticationService.vacols_regional_offices = {
        "RO21" => "pinkpowerranger" }
    end

    context "when vacols authentication passes" do
      let(:password) { "pinkpowerranger" }

      it "sets regional_office in the session" do
        is_expected.to be_truthy
        expect(user.regional_office).to eq("RO21")
      end
    end

    context "when vacols authentication fails" do
      let(:password) { "redpowerranger" }

      it "doesn't set regional_office in the session" do
        is_expected.to be_falsey
        expect(user.regional_office).to be_nil
      end
    end
  end

  context ".from_session" do
    subject { User.from_session(session) }
    context "gets a user object from a session" do
      before do
        session["user"]["roles"] = ["Do the thing"]
        session[:regional_office] = "283"
      end

      it do
        is_expected.to be_an_instance_of(User)
        expect(subject.roles).to eq(["Do the thing"])
        expect(subject.regional_office).to eq("283")
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
end
