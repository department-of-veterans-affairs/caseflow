# frozen_string_literal: true

describe HigherLevelReviewsController, :postgres, type: :controller do
  before do
    User.stub = user
  end

  let(:veteran) { create(:veteran) }
  let(:hlr) do
    create(:higher_level_review,
           :with_end_product_establishment,
           :processed,
           intake: create(:intake),
           veteran_file_number: veteran.file_number).reload
  end
  let(:user) { User.authenticate!(roles: ["Mail Intake"]) }

  describe "#edit" do
    before do
      hlr.establish!
    end

    it "finds by UUID" do
      get :edit, params: { claim_id: hlr.uuid }

      expect(response.status).to eq 200
    end

    it "finds by EPE reference_id" do
      get :edit, params: { claim_id: hlr.end_product_establishments.first.reference_id }

      expect(response.status).to eq 200
    end

    context "rating is locked" do
      before do
        allow(Rating).to receive(:fetch_in_range).and_raise(
          PromulgatedRating::LockedRatingError.new(message: "locked!")
        )
      end

      let!(:request_issue) do
        create(
          :request_issue,
          contested_rating_issue_reference_id: "123",
          decision_review: hlr,
          end_product_establishment: hlr.end_product_establishments.first
        )
      end

      it "returns 422 error" do
        get :edit, params: { claim_id: hlr.uuid }

        expect(response.status).to eq 422
      end
    end
  end
end
