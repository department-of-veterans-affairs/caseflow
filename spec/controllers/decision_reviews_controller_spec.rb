describe DecisionReviewsController, type: :controller do
  before do
    FeatureToggle.enable!(:decision_reviews)
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
    User.stub = user
  end

  after do
    FeatureToggle.disable!(:decision_reviews)
  end

  let(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
  let(:user) { create(:default_user) }

  describe "#index" do
    context "user is not in org" do
      it "returns unauthorized" do
        get :index, params: { business_line_slug: non_comp_org.url }

        expect(response.status).to eq 302
        expect(response.body).to match(/unauthorized/)
      end
    end

    context "user is in org" do
      before do
        OrganizationsUser.add_user_to_organization(user, non_comp_org)
      end

      it "displays org queue page" do
        get :index, params: { business_line_slug: non_comp_org.url }

        expect(response.status).to eq 200
      end
    end

    context "business-line-slug is not found" do
      it "returns 404" do
        get :index, params: { business_line_slug: "foobar" }

        expect(response.status).to eq 404
      end
    end
  end

  describe "#show" do
    let(:task) { create(:higher_level_review_task).becomes(DecisionReviewTask) }

    context "user is in org" do
      before do
        OrganizationsUser.add_user_to_organization(user, non_comp_org)
      end

      it "displays task details page" do
        get :show, params: { decision_review_business_line_slug: non_comp_org.url, task_id: task.id }

        expect(response.status).to eq 200
      end

      context "task does not exist" do
        it "returns 404" do
          get :show, params: { decision_review_business_line_slug: non_comp_org.url, task_id: 0 }

          expect(response.status).to eq 404
        end
      end
    end

    context "user is not in org" do
      it "returns unauthorized" do
        get :show, params: { decision_review_business_line_slug: non_comp_org.url, task_id: task.id }

        expect(response.status).to eq 302
        expect(response.body).to match(/unauthorized/)
      end
    end
  end

  describe "#update" do
    let(:veteran) { create(:veteran) }
    let(:task) { create(:higher_level_review_task).becomes(DecisionReviewTask) }
    let!(:request_issues) do
      [
        create(:request_issue, :rating, review_request: task.appeal),
        create(:request_issue, :nonrating, review_request: task.appeal)
      ]
    end

    context "user is in org" do
      before do
        OrganizationsUser.add_user_to_organization(user, non_comp_org)
        task.appeal.update!(veteran_file_number: veteran.file_number)
      end

      let(:decision_date) { "2018-10-1" }

      it "creates decision issues for each request issue", focus: true do
        put :update, params: { decision_review_business_line_slug: non_comp_org.url, task_id: task.id,
                               decision_issues: [
                                 {
                                   request_issue_id: request_issues.first.id,
                                   disposition: "Granted",
                                   description: "a rating note"
                                 },
                                 {
                                   request_issue_id: request_issues.second.id,
                                   disposition: "Denied",
                                   description: "a nonrating note"
                                 }
                               ],
                               decision_date: decision_date }

        datetime = Date.parse(decision_date).to_datetime

        expect(response.status).to eq(204)
        task.reload
        expect(task.appeal.decision_issues.length).to eq(2)
        expect(task.appeal.decision_issues.find_by(
                 disposition: "Granted",
                 description: "a rating note",
                 promulgation_date: datetime
        )).to_not be_nil
        expect(task.appeal.decision_issues.find_by(
                 disposition: "Denied",
                 description: "a nonrating note",
                 promulgation_date: datetime
        )).to_not be_nil
        expect(task.status).to eq("completed")
        expect(task.completed_at).to eq(Time.zone.now)
      end

      it "returns 400 when there is not a matching decision issue for each request issue" do
        put :update, params: { decision_review_business_line_slug: non_comp_org.url, task_id: task.id,
                               decision_issues: [
                                 {
                                   request_issue_id: request_issues.first.id,
                                   disposition: "Granted",
                                   description: "a rating note"
                                 }
                               ],
                               decision_date: decision_date }

        expect(response.status).to eq(400)
      end
    end
  end
end
