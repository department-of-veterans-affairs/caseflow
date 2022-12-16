# frozen_string_literal: true

describe DecisionReviewsController, :postgres, type: :controller do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
    User.stub = user
  end

  let(:non_comp_org) { create(:business_line, name: "National Cemetery Administration", url: "nca") }
  let(:user) { create(:default_user) }

  describe "#index" do
    context "user is not in org" do
      it "returns unauthorized" do
        get :index, params: { business_line_slug: non_comp_org.url }

        expect(response.status).to eq 302
        expect(response.body).to match(/unauthorized/)
      end
    end

    context "user has Admin Intake role" do
      let(:user) { User.authenticate!(roles: ["Admin Intake"]) }

      it "displays org queue page" do
        get :index, params: { business_line_slug: non_comp_org.url }

        expect(response.status).to eq 200
      end
    end

    context "user is in org" do
      before do
        non_comp_org.add_user(user)
      end

      it "displays org queue page" do
        get :index, params: { business_line_slug: non_comp_org.url }

        expect(response.status).to eq 200
      end

      context "user has an unknown station_id" do
        before do
          user.station_id = "xxx"
        end

        it "redirects to /login" do
          get :index, params: { business_line_slug: non_comp_org.url }

          expect(response.status).to eq 302
          expect(response.body).to match(/login/)
        end
      end
    end

    context "business-line-slug is not found" do
      it "returns 404" do
        get :index, params: { business_line_slug: "foobar" }

        expect(response.status).to eq 404
      end
    end

    context "shows csv" do
      let!(:user) { User.authenticate!(roles: ["Admin Intake"]) }
      let!(:task) { create(:higher_level_review_task, :completed, assigned_to: non_comp_org) }

      it "displays csv file" do
        get :index, params: { business_line_slug: non_comp_org.url }, format: :csv

        expect(response.status).to eq 200
        expect(response.headers["Content-Type"]).to include "text/csv"
        expect(response.body).to start_with("business_line")
        expect(response.body.match?(task.appeal_type)).to eq true
      end
    end
  end

  describe "#show" do
    let(:task) { create(:higher_level_review_task) }

    context "user is in org" do
      before do
        non_comp_org.add_user(user)
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

      context "when it is a veteran record request and veteran is not accessible by user" do
        let(:task) { create(:veteran_record_request_task) }
        before do
          allow_any_instance_of(Veteran).to receive(:accessible?).and_return(false)
        end

        it "returns 403" do
          get :show, params: { decision_review_business_line_slug: non_comp_org.url, task_id: task.id }

          expect(response.status).to eq 403
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
    let(:decision_date) { "2018-10-1" }

    before do
      non_comp_org.add_user(user)
      task.appeal.update!(veteran_file_number: veteran.file_number)
    end

    context "with board grant effectuation task" do
      before do
        @raven_called = false
        allow(Raven).to receive(:capture_exception) { @raven_called = true }
      end

      let(:task) do
        create(:board_grant_effectuation_task, :in_progress, assigned_to: non_comp_org)
      end

      it "marks task as completed" do
        put :update, params: { decision_review_business_line_slug: non_comp_org.url, task_id: task.id }

        expect(response.status).to eq(200)
        response_data = JSON.parse(response.body)
        expect(response_data["in_progress_tasks"]).to eq([])
        expect(response_data["completed_tasks"].length).to eq(1)
        task.reload
        expect(task.status).to eq("completed")
        expect(task.closed_at).to eq(Time.zone.now)
      end

      it "returns 400 when the task has already been completed" do
        task.update!(status: "completed")

        put :update, params: { decision_review_business_line_slug: non_comp_org.url, task_id: task.id }
        expect(response.status).to eq(400)
        expect(@raven_called).to eq(true)
      end
    end

    context "with decision review task" do
      let(:task) { create(:higher_level_review_task, :in_progress, assigned_to: non_comp_org) }

      let!(:request_issues) do
        [
          create(:request_issue, :rating, decision_review: task.appeal, benefit_type: non_comp_org.url),
          create(:request_issue, :nonrating, decision_review: task.appeal, benefit_type: non_comp_org.url)
        ]
      end

      it "creates decision issues for each request issue" do
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

        datetime = Date.parse(decision_date).in_time_zone(Time.zone)

        expect(response.status).to eq(200)
        response_data = JSON.parse(response.body)
        expect(response_data["in_progress_tasks"]).to eq([])
        expect(response_data["completed_tasks"].length).to eq(1)

        task.reload
        expect(task.appeal.decision_issues.length).to eq(2)
        expect(task.appeal.decision_issues.find_by(
                 disposition: "Granted",
                 description: "a rating note",
                 caseflow_decision_date: datetime
               )).to_not be_nil
        expect(task.appeal.decision_issues.find_by(
                 disposition: "Denied",
                 description: "a nonrating note",
                 caseflow_decision_date: datetime
               )).to_not be_nil
        expect(task.status).to eq("completed")
        expect(task.closed_at).to eq(Time.zone.now)
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

      it "returns 400 when the task has already been completed" do
        task.update!(status: "completed")

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

        expect(response.status).to eq(400)
      end
    end
  end

  describe "Acquiring decision review tasks via #index" do
    let(:veteran) { create(:veteran) }
    let!(:in_progress_tasks) do
      (0...32).map do |task_num|
        task = create(
          :higher_level_review_task,
          assigned_to: non_comp_org,
          assigned_at: task_num.days.ago
        )
        task.appeal.update!(veteran_file_number: veteran.file_number)
        create(:request_issue, :nonrating, decision_review: task.appeal, benefit_type: non_comp_org.url)

        task
      end
    end

    let!(:completed_tasks) do
      (1..20).map do |task_num|
        task = create(
          :higher_level_review_task,
          assigned_to: non_comp_org,
          assigned_at: task_num.days.ago,
          closed_at: task_num.hours.ago
        )
        task.completed!
        task.appeal.update!(veteran_file_number: veteran.file_number)

        task
      end
    end

    before { non_comp_org.add_user(user) }

    subject { get :index, params: query_params, format: :json }

    context "in_progress_tasks" do
      let(:query_params) do
        {
          business_line_slug: non_comp_org.url,
          tab: "in_progress"
        }
      end

      it "page 1 displays first 15 tasks" do
        query_params[:page] = 1

        subject

        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)

        expect(response_body["total_task_count"]).to eq 32
        expect(response_body["tasks_per_page"]).to eq 15
        expect(response_body["task_page_count"]).to eq 3

        expect(
          task_ids_from_response_body(response_body)
        ).to match_array task_ids_from_seed(in_progress_tasks, (0...15), :assigned_at)
      end

      it "page 3 displays last 2 tasks" do
        query_params[:page] = 3

        subject

        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)

        expect(response_body["total_task_count"]).to eq 32
        expect(response_body["tasks_per_page"]).to eq 15
        expect(response_body["task_page_count"]).to eq 3

        expect(
          task_ids_from_response_body(response_body)
        ).to match_array task_ids_from_seed(in_progress_tasks, (-2..in_progress_tasks.size), :assigned_at)
      end
    end

    context "completed_tasks" do
      let(:query_params) do
        {
          business_line_slug: non_comp_org.url,
          tab: "completed"
        }
      end

      it "page 1 displays first 15 tasks" do
        query_params[:page] = 1

        subject

        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)

        expect(response_body["total_task_count"]).to eq 40
        expect(response_body["tasks_per_page"]).to eq 15
        expect(response_body["task_page_count"]).to eq 3

        expect(
          task_ids_from_response_body(response_body)
        ).to match_array task_ids_from_seed(completed_tasks, (0...15), :closed_at)
      end

      it "page 2 displays last 5 tasks" do
        query_params[:page] = 2

        subject

        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)

        expect(response_body["total_task_count"]).to eq 20
        expect(response_body["tasks_per_page"]).to eq 15
        expect(response_body["task_page_count"]).to eq 2

        expect(
          task_ids_from_response_body(response_body)
        ).to match_array task_ids_from_seed(completed_tasks, (-5..completed_tasks.size), :closed_at)
      end
    end

    it "throws 404 error if unrecognized tab name is provided" do
      get :index,
          params: {
            business_line_slug: non_comp_org.url,
            tab: "something_not_valid"
          },
          format: :json

      expect(response.status).to eq(404)
      expect(JSON.parse(response.body)["error"]).to eq "Tab name provided could not be found"
    end

    it "throws 400 error if tab name is omitted" do
      get :index, params: { business_line_slug: non_comp_org.url }, format: :json

      expect(response.status).to eq(400)
      expect(JSON.parse(response.body)["error"]).to eq "'tab' parameter is required."
    end
  end

  def task_ids_from_response_body(response_body)
    response_body["tasks"]["data"].map { |task| task["id"].to_i }
  end

  def task_ids_from_seed(tasks, range, sorted_by)
    tasks.sort_by(&sorted_by).reverse[range].pluck(:id)
  end
end
