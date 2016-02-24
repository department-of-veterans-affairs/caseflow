User.authentication_service = Fakes::AuthenticationService

describe User do
  let(:session) { {} }
  let(:user) { User.new(session: session) }

  context "#username" do
    subject { user.username }

    context "when ssoi authentication is enabled" do
      before do
        Fakes::AuthenticationService.ssoi_enabled = true
        session[:username] = "Russeller"
      end

      it { is_expected.to eq("Russeller") }
    end

    context "when ssoi authentication is disabled" do
      before do
        Fakes::AuthenticationService.ssoi_enabled = false
        Fakes::AuthenticationService.ssoi_username = "Shaner"
      end

      it { is_expected.to eq("Shaner") }
    end
  end

  context "#regional_office" do
    subject { user.regional_office }
    before { session[:regional_office] = "RO17" }
    it { is_expected.to eq("RO17") }
  end

  context "#display_name" do
    subject { user.display_name }

    before do
      Fakes::AuthenticationService.ssoi_enabled = true
      session[:regional_office] = "RO77"
    end

    context "when username is set" do
      before { session[:username] = "Shaner" }
      it { is_expected.to eq("Shaner (RO77)") }
    end

    context "when username isn't set" do
      before { session[:username] = nil }
      it { is_expected.to eq("RO77") }
    end
  end

  context "#authenticated?" do
    subject { user.authenticated? }
    before { Fakes::AuthenticationService.ssoi_enabled = true }

    context "when ssoi is authenticated" do
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

    context "when ssoi isn't authenticated" do
      before { session[:username] = nil }
      before { session[:regional_office] = "RO77" }

      it { is_expected.to be_falsy }
    end
  end

  context "#ssoi_authenticated?" do
    subject { user.ssoi_authenticated? }
    before { Fakes::AuthenticationService.ssoi_enabled = true }

    context "when username is set" do
      before { session[:username] = "USER" }
      it { is_expected.to be_truthy }
    end

    context "when username isn't set" do
      before { session[:username] = nil }
      it { is_expected.to be_falsy }
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
end
