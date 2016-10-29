User.authentication_service = Fakes::AuthenticationService

describe User do
  let(:session) { { "user" => { 'id' => "123", 'station_id' => "456" } } }
  let(:user) { User.from_session(session) }

  context "#regional_office" do
    context "when RO can't be determined using station_id" do
      subject { user.regional_office }
      before { session["user"]["station_id"] = "405"  }
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
        session["user"] = { "id" => "Shaner" }
        session[:regional_office] = "RO77"
      end
      it { is_expected.to eq("Shaner (RO77)") }
    end

    context "when just username is set" do
      before { session["user"] = { "id" => "Shaner" } }
      it { is_expected.to eq("Shaner") }
    end
  end

  context "#can?" do
    subject { user.can?("Do the thing") }

    context "when roles are nil" do
      it { is_expected.to be_falsey }
    end

    context "when roles don't contain the thing" do
      it { is_expected.to be_falsey }
    end

    context "when roles contains the thing" do
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
end
