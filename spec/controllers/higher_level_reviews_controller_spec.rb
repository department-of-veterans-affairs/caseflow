# frozen_string_literal: true

describe HigherLevelReviewsController, type: :controller do
  before do
    FeatureToggle.enable!(:intake)

    User.stub = user
    user.update(roles: user.roles << "Mail Intake")
    Functions.grant!("Mail Intake", users: [user.css_id])
  end

  after do
    FeatureToggle.disable!(:intake)
  end

  let(:hlr) { create(:higher_level_review, :with_end_product_establishment).reload }
  let(:user) { create(:default_user) }

  describe "#edit" do
    it "finds by UUID" do
      get :edit, params: { claim_id: hlr.uuid }

      expect(response.status).to eq 200
    end

    it "finds by EPE reference_id" do
      hlr.end_product_establishments.first.update!(reference_id: "abc123")

      get :edit, params: { claim_id: hlr.end_product_establishments.first.reference_id }

      expect(response.status).to eq 200
    end
  end
end
