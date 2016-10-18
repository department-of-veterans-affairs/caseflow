User.authentication_service = Fakes::AuthenticationService

describe User do
  let(:session) { {} }
  let(:user) { User.new(session: session) }

  context "#regional_office" do
    subject { user.regional_office }
    before { session[:regional_office] = "RO17" }
    it { is_expected.to eq("RO17") }
  end

  context "#timezone" do
    context "when ro is set" do
      subject { user.timezone }
      before { session[:regional_office] = "RO26" }
      it { is_expected.to eq("America/Indiana/Indianapolis") }
    end

    context "when ro isn't set" do
      subject { user.timezone }
      before { session[:regional_office] = nil }
      it { is_expected.to eq("America/Chicago") }
    end
  end

  context "#display_name" do
    subject { user.display_name }

    context "when username and RO are both set" do
      before do
        session[:username] = "Shaner"
        session[:regional_office] = "RO77"
      end
      it { is_expected.to eq("Shaner (RO77)") }
    end

    context "when just username is set" do
      before { session[:username] = "Shaner" }
      it { is_expected.to eq("Shaner") }
    end
  end

  context "#can?" do
    subject { user.can?("Do the thing") }

    context "when user is not a CSS user" do
      let(:session) { { id: "SHANE" } }
      it { is_expected.to be_truthy }
    end

    context "when roles are nil" do
      let(:session) { { "user" => {} } }
      it { is_expected.to be_falsey }
    end

    context "when roles don't contain the thing" do
      let(:session) { { "user" => { "roles" => ["Do the other thing"] } } }
      it { is_expected.to be_falsey }
    end

    context "when roles contains the thing" do
      let(:session) { { "user" => { "roles" => ["Do the thing"] } } }
      it { is_expected.to be_truthy }
    end
  end

  context "#authenticated?" do
    subject { user.authenticated? }
    before { session[:username] = "USER" }

    context "when regional_office set" do
      before { session[:regional_office] = "RO77" }
      it { is_expected.to be_truthy }
    end

    context "when regional_office isn't set" do
      before { session[:regional_office] = nil }
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
        expect(session[:regional_office]).to eq("RO21")
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
        expect(session[:regional_office]).to eq("RO21")
      end
    end

    context "when vacols authentication fails" do
      let(:password) { "redpowerranger" }

      it "doesn't set regional_office in the session" do
        is_expected.to be_falsey
        expect(session[:regional_office]).to be_nil
      end
    end
  end

  context "#unauthenticate" do
    before do
      session[:regional_office] = "RO33"
      session[:username] = "test user"
    end

    it "clears regional_office and username" do
      user.unauthenticate
      expect(session[:regional_office]).to be_nil
      expect(session[:username]).to be_nil
    end
  end

  context "#authenticate_ssoi" do
    it "fails if missing id" do
      result = user.authenticate_ssoi({})
      expect(result).to be_falsey
    end

    it "succeeds if uid is present" do
      result = user.authenticate_ssoi("uid" => "xyz@va.gov")
      expect(result).to be_truthy
      expect(user.username).to eq("xyz@va.gov")
    end
  end
end
