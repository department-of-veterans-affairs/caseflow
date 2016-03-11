User.authentication_service = Fakes::AuthenticationService

describe User do
  let(:session) { {} }
  let(:user) { User.new(session: session) }

  context "#regional_office" do
    subject { user.regional_office }
    before { session[:regional_office] = "RO17" }
    it { is_expected.to eq("RO17") }
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

  context "#can_access?" do
    before { session[:regional_office] = "RO1" }
    let(:appeal) { Appeal.new }

    subject { user.can_access?(appeal) }

    context "when appeal ro key matches user's ro" do
      before { appeal.regional_office_key = "RO1" }
      it { is_expected.to be_truthy }
    end

    context "when appeal ro key doesn't match user's ro" do
      before { appeal.regional_office_key = "RO2" }
      it { is_expected.to be_falsey }
    end
  end

  context "#authenticated?" do
    subject { user.authenticated? }

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
