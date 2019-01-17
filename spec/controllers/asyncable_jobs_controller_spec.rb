describe AsyncableJobsController, type: :controller do
  before do
    User.stub = user
  end

  describe "#index" do
    context "user is not Admin Intake" do
      let(:user) { create(:default_user) }

      it "returns unauthorized" do
        get :index

        expect(response.status).to eq 302
        expect(response.body).to match(/unauthorized/)
      end
    end

    context "user is Admin Intake" do
      let(:user) { User.authenticate!(roles: ["Admin Intake"]) }
      let!(:hlr) { create(:higher_level_review, establishment_submitted_at: 7.days.ago) }
      let!(:sc) { create(:supplemental_claim, establishment_submitted_at: 7.days.ago) }

      context "no asyncable klass specified" do
        render_views

        it "renders table of all expired jobs" do
          get :index, as: :html

          expect(response.status).to eq 200
          expect(response.body).to match(/SupplementalClaim/)
          expect(response.body).to match(/HigherLevelReview/)
        end
      end

      context "asyncable klass specified" do
        render_views

        it "renders table limited to the klass" do
          get :index, as: :html, params: { asyncable_job_klass: "HigherLevelReview" }

          expect(response.status).to eq 200
          expect(response.body).to match(/HigherLevelReview/)
          expect(response.body).to_not match(/SupplementalClaim/)
        end
      end

      context "asyncable klass does not include Asyncable concern" do
        it "returns 404 error" do
          get :index, params: { asyncable_job_klass: "Intake" }

          expect(response.status).to eq 404
        end
      end
    end
  end
end
