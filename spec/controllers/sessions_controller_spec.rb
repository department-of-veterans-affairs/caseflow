# frozen_string_literal: true

describe SessionsController, type: :controller do
  let(:user) { create(:user) }
  let(:admin_user) { create(:user) }

  describe "#destroy" do
    context "normal user" do
      before do
        session["user"] = Fakes::AuthenticationService.get_user_session(user.id)
        session["return_to"] = "foobar"
      end

      it "clears session and logs out user" do
        get :destroy

        expect(response).to redirect_to "/"
        expect(session["return_to"]).to be_nil
        expect(session["user"]).to be_nil
      end
    end

    context "global admin" do
      before do
        session["global_admin"] = admin_user.id
        session["user"] = Fakes::AuthenticationService.get_user_session(user.id)
        session["return_to"] = "foobar"
      end

      it "restores session to admin user" do
        get :destroy

        expect(response).to redirect_to "/test/users"
        expect(session["return_to"]).to be_nil
        expect(session["user"]["pg_user_id"]).to eq admin_user.id
        expect(session["global_admin"]).to be_nil
      end
    end
  end
end
