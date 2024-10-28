# frozen_string_literal: true

# This is needed for the generate_report action since the testing environment does not eager load service files
require Rails.root.join("app", "services", "claim_change_history", "change_history_reporter.rb")
require Rails.root.join("app", "services", "claim_change_history", "claim_history_service.rb")
require Rails.root.join("app", "services", "claim_change_history", "change_history_filter_parser.rb")
require Rails.root.join("app", "services", "claim_change_history", "claim_history_event.rb")
require Rails.root.join("app", "services", "claim_change_history", "change_history_event_serializer.rb")

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
        expect(response.body.match?(task.appeal.class.review_title)).to eq true
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

      context "VHA business line" do
        let(:vha_org) { VhaBusinessLine.singleton }
        let(:task) { create(:higher_level_review_task, :in_progress, assigned_to: vha_org) }
        let!(:request_issues) do
          [
            create(:request_issue, :rating, decision_review: task.appeal, benefit_type: vha_org.url),
            create(:request_issue, :nonrating, decision_review: task.appeal, benefit_type: vha_org.url)
          ]
        end

        before do
          vha_org.add_user(user)
          OrganizationsUser.make_user_admin(user, vha_org)
        end

        it "returns 400 when the decision date is invalid" do
          put :update, params: { decision_review_business_line_slug: "vha", task_id: task.id,
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
                                 decision_date: 500.years.ago }

          response_body = JSON.parse(response.body)

          expect(response.status).to eq(400)
          expect(response_body["error_code"]).to eq("invalid_decision_date")
        end
      end
    end
  end

  describe "Acquiring decision review tasks via #index" do
    let(:veteran) { create(:veteran) }
    let!(:in_progress_hlr_tasks) do
      (0...32).map do |task_num|
        task = create(
          :higher_level_review_task,
          assigned_to: non_comp_org,
          assigned_at: task_num.days.ago
        )
        task.appeal.update!(veteran_file_number: veteran.file_number)
        create(:request_issue, :nonrating, decision_review: task.appeal, benefit_type: non_comp_org.url)

        # Generate some random request issues for testing issue type filters
        generate_request_issues(task, non_comp_org)

        task
      end
    end

    # Throw in some on hold tasks as well to make sure generic businessline in progress includes on_hold tasks
    let!(:on_hold_hlr_tasks) do
      (0...20).map do |task_num|
        task = create(
          :higher_level_review_task,
          assigned_to: non_comp_org,
          assigned_at: task_num.minutes.ago
        )
        task.on_hold!
        task.appeal.update!(veteran_file_number: veteran.file_number)
        create(:request_issue, :nonrating, decision_review: task.appeal, benefit_type: non_comp_org.url)

        # Generate some random request issues for testing issue type filters
        generate_request_issues(task, non_comp_org)

        task
      end
    end

    let!(:in_progress_sc_tasks) do
      (0...32).map do |task_num|
        task = create(
          :supplemental_claim_task,
          assigned_to: non_comp_org,
          assigned_at: task_num.minutes.ago
        )
        task.appeal.update!(veteran_file_number: veteran.file_number)
        create(:request_issue, :nonrating, decision_review: task.appeal, benefit_type: non_comp_org.url)

        # Generate some random request issues for testing issue type filters
        generate_request_issues(task, non_comp_org)

        task
      end
    end

    let!(:in_progress_remand_tasks) do
      (0...10).map do |task_num|
        task = create(
          :remand_task,
          assigned_to: non_comp_org,
          assigned_at: task_num.minutes.ago + 1.minute.ago
        )
        task.appeal.update!(veteran_file_number: veteran.file_number)
        create(:request_issue, :nonrating, decision_review: task.appeal, benefit_type: non_comp_org.url)

        # Generate some random request issues for testing issue type filters
        generate_request_issues(task, non_comp_org)

        task
      end
    end

    let!(:completed_hlr_tasks) do
      (1..20).map do |task_num|
        task = create(
          :higher_level_review_task,
          assigned_to: non_comp_org,
          assigned_at: task_num.days.ago,
          closed_at: (2 * task_num).hours.ago
        )
        task.completed!
        # Explicitly set the closed_at time again to try to avoid test flakiness
        task.closed_at = Time.zone.now - (2 * task_num).hours
        task.appeal.update!(veteran_file_number: veteran.file_number)
        create(:request_issue, :nonrating, decision_review: task.appeal, benefit_type: non_comp_org.url)

        # Generate some random request issues for testing issue type filters
        generate_request_issues(task, non_comp_org)

        task.save
        # Attempt to reload after save to avoid potential test flakiness
        task.reload
      end
    end

    let!(:completed_sc_tasks) do
      (1..20).map do |task_num|
        task = create(
          :supplemental_claim_task,
          assigned_to: non_comp_org,
          assigned_at: task_num.days.ago,
          closed_at: (2 * task_num).hours.ago
        )
        task.completed!
        # Explicitly set the closed_at time again to try to avoid test flakiness
        task.closed_at = Time.zone.now - (2 * task_num).hours
        task.appeal.update!(veteran_file_number: veteran.file_number)
        create(:request_issue, :nonrating, decision_review: task.appeal, benefit_type: non_comp_org.url)

        # Generate some random request issues for testing issue type filters
        generate_request_issues(task, non_comp_org)

        task.save
        # Attempt to reload after save to avoid potential test flakiness
        task.reload
      end
    end

    let!(:completed_remand_tasks) do
      (1..10).map do |task_num|
        task = create(
          :remand_task,
          assigned_to: non_comp_org,
          assigned_at: task_num.days.ago,
          closed_at: (2 * task_num).hours.ago
        )
        task.completed!
        # Explicitly set the closed_at time again to try to avoid test flakiness
        task.closed_at = Time.zone.now - (2 * task_num).hours
        task.appeal.update!(veteran_file_number: veteran.file_number)
        create(:request_issue, :nonrating, decision_review: task.appeal, benefit_type: non_comp_org.url)

        # Generate some random request issues for testing issue type filters
        generate_request_issues(task, non_comp_org)

        task.save
        # Attempt to reload after save to avoid potential test flakiness
        task.reload
      end
    end

    before { non_comp_org.add_user(user) }

    subject { get :index, params: query_params, format: :json }

    shared_examples "task query filtering" do
      it "Only Supplemental Claim Tasks are shown when filtered" do
        get :index,
            params: query_params.merge(
              filter: ["col=decisionReviewType&val=SupplementalClaim"],
              page: 3
            ),
            format: :json

        response_body = JSON.parse(response.body)

        expect(
          response_body["tasks"]["data"].all? do |task|
            task["type"] == "decision_review_task" && task["attributes"]["type"] == "Supplemental Claim"
          end
        ).to be true
      end

      it "Only Higher-Level Review Tasks are shown when filtered" do
        get :index,
            params: query_params.merge(
              filter: ["col=decisionReviewType&val=HigherLevelReview"],
              page: 3
            ),
            format: :json

        response_body = JSON.parse(response.body)

        expect(
          response_body["tasks"]["data"].all? do |task|
            task["type"] == "decision_review_task" && task["attributes"]["type"] == "Higher-Level Review"
          end
        ).to be true
      end

      it "Only Remand Tasks are shown when filtered" do
        get :index,
            params: query_params.merge(
              filter: ["col=decisionReviewType&val=Remand"],
              page: 1
            ),
            format: :json

        response_body = JSON.parse(response.body)

        expect(
          response_body["tasks"]["data"].all? do |task|
            task["type"] == "decision_review_task" && task["attributes"]["type"] == "Remand"
          end
        ).to be true
      end
    end

    shared_examples "issue type query filtering" do
      it "Only Tasks with request issues with the type Beneficiary Travel are shown when filtered" do
        get :index,
            params: query_params.merge(
              filter: ["col=issueTypesColumn&val=Beneficiary Travel"],
              page: 1
            ),
            format: :json

        response_body = JSON.parse(response.body)

        expect(
          response_body["tasks"]["data"].all? do |task|
            task["attributes"]["issue_types"].include?("Beneficiary Travel")
          end
        ).to be true
      end

      it "Only Tasks with request issues and with decision review type HigherLevel Review are shown when filtered" do
        get :index,
            params: query_params.merge(
              filter: ["col=issueTypesColumn&val=Beneficiary Travel", "col=decisionReviewType&val=HigherLevelReview"],
              page: 1
            ),
            format: :json

        response_body = JSON.parse(response.body)

        expect(
          response_body["tasks"]["data"].all? do |task|
            task["attributes"]["issue_types"].include?("Beneficiary Travel") &&
            task["type"] == "decision_review_task" &&
            task["attributes"]["type"] == "Higher-Level Review"
          end
        ).to be true
      end
    end

    context "in_progress_tasks" do
      let(:query_params) do
        {
          business_line_slug: non_comp_org.url,
          tab: "in_progress"
        }
      end

      let(:in_progress_tasks) do
        in_progress_hlr_tasks + on_hold_hlr_tasks + in_progress_sc_tasks + in_progress_remand_tasks
      end

      include_examples "task query filtering"
      include_examples "issue type query filtering"

      it "page 1 displays first 15 tasks" do
        query_params[:page] = 1

        subject

        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)

        expect(response_body["total_task_count"]).to eq 94
        expect(response_body["tasks_per_page"]).to eq 15
        expect(response_body["task_page_count"]).to eq 7

        expect(
          task_ids_from_response_body(response_body)
        ).to match_array task_ids_from_seed(in_progress_tasks, (0...15), :assigned_at)
      end

      it "page 7 displays last 4 tasks" do
        query_params[:page] = 7

        subject

        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)

        expect(response_body["total_task_count"]).to eq 94
        expect(response_body["tasks_per_page"]).to eq 15
        expect(response_body["task_page_count"]).to eq 7

        expect(
          task_ids_from_response_body(response_body)
        ).to match_array task_ids_from_seed(in_progress_tasks, (-4..in_progress_tasks.size), :assigned_at)
      end
    end

    context "completed_tasks" do
      let(:query_params) do
        {
          business_line_slug: non_comp_org.url,
          tab: "completed"
        }
      end

      let(:completed_tasks) { completed_sc_tasks + completed_hlr_tasks + completed_remand_tasks }

      include_examples "task query filtering"
      include_examples "issue type query filtering"

      it "page 1 displays first 15 tasks" do
        query_params[:page] = 1

        subject

        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)

        expect(response_body["total_task_count"]).to eq 50
        expect(response_body["tasks_per_page"]).to eq 15
        expect(response_body["task_page_count"]).to eq 4

        expect(
          task_ids_from_response_body(response_body)
        ).to match_array task_ids_from_seed(completed_tasks, (0...15), :closed_at)
      end

      it "page 4 displays last 5 tasks" do
        query_params[:page] = 4

        subject

        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)

        expect(response_body["total_task_count"]).to eq 50
        expect(response_body["tasks_per_page"]).to eq 15
        expect(response_body["task_page_count"]).to eq 4

        expect(
          task_ids_from_response_body(response_body)
        ).to match_array task_ids_from_seed(completed_tasks, (-5..completed_tasks.size), :closed_at)
      end
    end

    context "vha org with incomplete tasks" do
      let(:non_comp_org) { VhaBusinessLine.singleton }

      context "incomplete_tasks" do
        let(:query_params) do
          {
            business_line_slug: non_comp_org.url,
            tab: "incomplete"
          }
        end

        let!(:on_hold_sc_tasks) do
          (0...20).map do |task_num|
            task = create(
              :supplemental_claim_task,
              assigned_to: non_comp_org,
              assigned_at: task_num.hours.ago
            )
            task.on_hold!
            task.appeal.update!(veteran_file_number: veteran.file_number)
            create(:request_issue, :nonrating, decision_review: task.appeal, benefit_type: non_comp_org.url)

            # Generate some random request issues for testing issue type filters
            generate_request_issues(task, non_comp_org)

            task
          end
        end

        let(:incomplete_tasks) { on_hold_hlr_tasks + on_hold_sc_tasks }

        include_examples "task query filtering"
        include_examples "issue type query filtering"

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
          ).to match_array task_ids_from_seed(incomplete_tasks, (0...15), :assigned_at)
        end

        it "page 3 displays last 10 tasks" do
          query_params[:page] = 3

          subject

          expect(response.status).to eq(200)
          response_body = JSON.parse(response.body)

          expect(response_body["total_task_count"]).to eq 40
          expect(response_body["tasks_per_page"]).to eq 15
          expect(response_body["task_page_count"]).to eq 3

          expect(
            task_ids_from_response_body(response_body)
          ).to match_array task_ids_from_seed(incomplete_tasks, (-10..incomplete_tasks.size), :assigned_at)
        end
      end

      context "in_progress_tasks" do
        let(:query_params) do
          {
            business_line_slug: non_comp_org.url,
            tab: "in_progress"
          }
        end

        # The Vha Businessline in_progress should not include on_hold since it uses active for the tasks query
        let(:in_progress_tasks) { in_progress_hlr_tasks + in_progress_sc_tasks + in_progress_remand_tasks }

        it "page 1 displays first 15 tasks" do
          query_params[:page] = 1

          subject

          expect(response.status).to eq(200)
          response_body = JSON.parse(response.body)

          expect(response_body["total_task_count"]).to eq 74
          expect(response_body["tasks_per_page"]).to eq 15
          expect(response_body["task_page_count"]).to eq 5

          expect(
            task_ids_from_response_body(response_body)
          ).to match_array task_ids_from_seed(in_progress_tasks, (0...15), :assigned_at)
        end
      end
    end

    context "vha org pending_tasks" do
      let(:non_comp_org) { VhaBusinessLine.singleton }

      context "pending_tasks" do
        let(:query_params) do
          {
            business_line_slug: non_comp_org.url,
            tab: "pending"
          }
        end

        let(:in_progress_tasks) { in_progress_hlr_tasks + in_progress_sc_tasks }

        let!(:pending_tasks) do
          (0...32).map do |task_num|
            task = create(
              :higher_level_review_task,
              assigned_to: non_comp_org,
              assigned_at: task_num.days.ago
            )
            task.appeal.update!(veteran_file_number: veteran.file_number)

            # Generate some random request issues for testing issue type filters
            generate_request_issues(task, non_comp_org)

            create(:issue_modification_request, decision_review: task.appeal, requestor: user)

            task
          end
        end

        let(:extra_issue_modifications_task) { pending_tasks.first }

        before do
          # Add an additional issue modification request to the first task for sorting
          create(:issue_modification_request, decision_review: extra_issue_modifications_task.appeal, requestor: user)
          extra_issue_modifications_task.reload
        end

        include_examples "task query filtering"
        include_examples "issue type query filtering"

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
          ).to match_array task_ids_from_seed(pending_tasks, (0...15), :assigned_at)
        end

        it "page 3 displays last 10 tasks" do
          query_params[:page] = 3

          subject

          expect(response.status).to eq(200)
          response_body = JSON.parse(response.body)

          expect(response_body["total_task_count"]).to eq 32
          expect(response_body["tasks_per_page"]).to eq 15
          expect(response_body["task_page_count"]).to eq 3

          expect(
            task_ids_from_response_body(response_body)
          ).to match_array task_ids_from_seed(pending_tasks, (-2..pending_tasks.size), :assigned_at)
        end

        it "sorts correctly by pending issue requests in descending order" do
          query_params[:page] = 1
          query_params[:sort_by] = "pendingIssueModificationRequest"

          subject
          response_body = JSON.parse(response.body)
          expect(response.status).to eq(200)
          expect(response_body["total_task_count"]).to eq 32
          expect(response_body["tasks_per_page"]).to eq 15
          expect(response_body["task_page_count"]).to eq 3

          expect(task_ids_from_response_body(response_body).first).to eq(extra_issue_modifications_task.id)
        end

        it "sorts correctly by pending issue requests in ascending order" do
          query_params[:page] = 3
          query_params[:order] = "asc"
          query_params[:sort_by] = "pendingIssueModificationRequest"

          subject
          response_body = JSON.parse(response.body)
          expect(response.status).to eq(200)
          expect(response_body["total_task_count"]).to eq 32
          expect(response_body["tasks_per_page"]).to eq 15
          expect(response_body["task_page_count"]).to eq 3

          expect(task_ids_from_response_body(response_body).last).to eq(extra_issue_modifications_task.id)
        end
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

  describe "#power_of_attorney" do
    let(:poa_task) do
      create(:supplemental_claim_poa_task)
    end

    context "get the appeals POA information" do
      subject do
        get :power_of_attorney,
            params: { use_route: "decision_reviews/#{non_comp_org.url}/tasks", task_id: poa_task.id },
            format: :json
      end

      it "returns a successful response" do
        expect(JSON.parse(subject.body)["representative_type"]).to eq "Attorney"
        expect(JSON.parse(subject.body)["representative_name"]).to eq "Clarence Darrow"
        expect(JSON.parse(subject.body)["representative_email_address"]).to eq "jamie.fakerton@caseflowdemo.com"
        expect(JSON.parse(subject.body)["representative_tz"]).to eq "America/Los_Angeles"
        expect(JSON.parse(subject.body)["poa_last_synced_at"]).to eq "2018-01-01T07:00:00.000-05:00"
      end
    end

    context "update POA Information" do
      subject do
        patch :update_power_of_attorney,
              params: { use_route: "decision_reviews/#{non_comp_org.url}/tasks", task_id: poa_task.id },
              format: :json
      end

      it "update and return POA information successfully" do
        subject
        assert_response(:success)
        expect(JSON.parse(subject.body)["power_of_attorney"]["representative_type"]).to eq "Attorney"
        expect(JSON.parse(subject.body)["power_of_attorney"]["representative_name"]).to eq "Clarence Darrow"
        expected_email = "jamie.fakerton@caseflowdemo.com"
        expect(JSON.parse(subject.body)["power_of_attorney"]["representative_email_address"]).to eq expected_email
        expect(JSON.parse(subject.body)["power_of_attorney"]["representative_tz"]).to eq "America/Los_Angeles"
      end
    end
  end

  describe "#history" do
    before do
      Timecop.travel(1.day.ago)
    end

    let(:task) { create(:higher_level_review_task) }

    context "task is in VHA" do
      let(:vha_org) { VhaBusinessLine.singleton }

      context "and user is not an admin" do
        before do
          vha_org.add_user(user)
        end

        it "returns unauthorized" do
          get :history, params: { task_id: task.id, decision_review_business_line_slug: vha_org.url }

          expect(response.status).to eq 302
          expect(response.body).to match(/unauthorized/)
        end
      end

      context "and user is an admin" do
        before do
          OrganizationsUser.make_user_admin(user, vha_org)
        end

        let!(:task_event) do
          create(:issue_modification_request,
                 :with_higher_level_review_with_decision,
                 :edit_of_request,
                 :update_decider,
                 :with_request_issue,
                 nonrating_issue_category: "Medical and Dental Care Reimbursement")
        end

        let!(:issue_modification_request_modification) do
          create(:issue_modification_request,
                 :with_request_issue,
                 request_type: "modification",
                 decision_review: task_event.decision_review)
        end

        let!(:issue_modification_request_withdrawal) do
          create(:issue_modification_request,
                 :with_request_issue,
                 :withdrawal,
                 decision_review: task_event.decision_review)
        end

        let!(:issue_modification_request_removal) do
          create(:issue_modification_request,
                 :with_request_issue,
                 request_type: "removal",
                 decision_review: task_event.decision_review)
        end
        let!(:issue_modification_request_cancel) do
          create(:issue_modification_request,
                 :cancel_of_request,
                 decision_review: task_event.decision_review)
        end

        let(:task_id) { task_event.decision_review.tasks.ids[0] }

        let!(:remand_task_event) do
          create(:remand_vha_task)
        end

        let!(:remand_task_event) do
          create(:remand_vha_task)
        end

        it "should return task details" do
          get :history, params: { task_id: task_id, decision_review_business_line_slug: vha_org.url },
                        format: :json

          expect(response.status).to eq 200

          res = JSON.parse(response.body)

          expected_events = [
            { "taskID" => task_id, "eventType" => "added_issue", "claimType" => "Higher-Level Review",
              "readableEventType" => "Added issue" },
            { "eventType" => "claim_creation", "readableEventType" => "Claim created" },
            { "eventType" => "in_progress", "readableEventType" => "Claim status - In progress" },
            { "eventType" => "completed_disposition", "readableEventType" => "Completed disposition" },
            { "eventType" => "addition", "readableEventType" => "Requested issue addition" },
            { "eventType" => "pending", "readableEventType" => "Claim status - Pending" },
            { "eventType" => "request_approved", "readableEventType" => "Approval of request - issue addition" },
            { "eventType" => "request_edited", "readableEventType" => "Edit of request - issue addition" },
            { "eventType" => "modification", "readableEventType" => "Requested issue modification" },
            { "eventType" => "removal", "readableEventType" => "Requested issue removal" },
            { "eventType" => "request_cancelled", "readableEventType" => "Cancellation of request" },
            { "eventType" => "withdrawal", "readableEventType" => "Requested issue withdrawal" }
          ]

          expected_events.each do |expected_attributes|
            expect(res).to include(
              a_hash_including("attributes" => a_hash_including(expected_attributes))
            )
          end
        end

        it "should return remand task details" do
          get :history, params: { task_id: remand_task_event.id, decision_review_business_line_slug: vha_org.url },
                        format: :json

          expect(response.status).to eq 200

          res = JSON.parse(response.body)

          expected_events = [
            { "taskID" => remand_task_event.id, "eventType" => "added_issue", "claimType" => "Remand" }
          ]

          expected_events.each do |expected_attributes|
            expect(res).to include(
              a_hash_including("attributes" => a_hash_including(expected_attributes))
            )
          end
        end

        it "should return remand task details" do
          get :history, params: { task_id: remand_task_event.id, decision_review_business_line_slug: vha_org.url },
                        format: :json

          expect(response.status).to eq 200

          res = JSON.parse(response.body)

          expected_events = [
            { "taskID" => remand_task_event.id, "eventType" => "added_issue", "claimType" => "Remand" }
          ]

          expected_events.each do |expected_attributes|
            expect(res).to include(
              a_hash_including("attributes" => a_hash_including(expected_attributes))
            )
          end
        end
      end
    end

    context "task is not in VHA" do
      before do
        non_comp_org.add_user(user)
        OrganizationsUser.make_user_admin(user, non_comp_org)
      end
      it "returns unauthorized" do
        get :history, params: { task_id: task.id, decision_review_business_line_slug: non_comp_org.url }

        expect(response.status).to eq 302
        expect(response.body).to match(/unauthorized/)
      end
    end
  end

  describe "#generate_report" do
    let(:non_comp_org) { VhaBusinessLine.singleton }

    context "business-line-slug is not found" do
      it "returns 404" do
        get :generate_report, params: { business_line_slug: "foobar" }

        expect(response.status).to eq 404
      end
    end

    context "user is not an org admin" do
      it "returns unauthorized" do
        get :generate_report, params: { business_line_slug: non_comp_org.url }

        expect(response.status).to eq 302
        expect(response.body).to match(/unauthorized/)
      end
    end

    context "user is an org admin" do
      let(:generate_report_filters) do
        {
          "report_type" => "event_type_action",
          "timing" => {
            "range" => "after",
            "start_date" => Time.zone.now
          },
          "days_waiting" => {
            "comparison_operator" => "moreThan",
            "value_one" => "6"
          },
          "personnel" => {
            "0" => "CAREGIVERADMIN",
            "1" => "VHAPOADMIN",
            "2" => "THOMAW2VACO"
          },
          "decision_review_type" => {
            "0" => "HigherLevelReview",
            "1" => "SupplementalClaim"
          },
          "business_line_slug" => "vha"
        }
      end

      before do
        OrganizationsUser.make_user_admin(user, non_comp_org)
      end

      it "renders the report generation template in HTML format" do
        get :generate_report, format: :html, params: { business_line_slug: non_comp_org.url }

        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to eq("text/html; charset=utf-8")
      end

      it "renders the report generation action in a css format" do
        get :generate_report, format: :csv,
                              params: { business_line_slug: non_comp_org.url }.merge(generate_report_filters)

        expect(response.headers["Content-Type"]).to eq("text/csv")
        expect(response.headers["Content-Disposition"]).to match(
          /^attachment; filename=\"taskreport-20180101_0700.csv\"/
        )
      end

      it "calls MetricsService to record metrics" do
        expect(MetricsService).to receive(:store_record_metric)
        get :generate_report, format: :csv,
                              params: { business_line_slug: non_comp_org.url }.merge(generate_report_filters)

        expect(response.status).to eq 200
      end

      context "missing report parameter" do
        it "raises a param is missing error when report type is missing from filters" do
          params = { business_line_slug: non_comp_org.url }.merge(generate_report_filters.except("report_type"))
          get :generate_report, format: :csv, params: params
          expect(response).to have_http_status(:bad_request)
          expect(response.content_type).to eq("application/json; charset=utf-8")
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("param is missing or the value is empty: reportType")
        end
      end
    end
  end

  def task_ids_from_response_body(response_body)
    response_body["tasks"]["data"].map { |task| task["id"].to_i }
  end

  def task_ids_from_seed(tasks, range, sorted_by)
    tasks.sort_by(&sorted_by).reverse[range].pluck(:id)
  end

  # Generate a few request issues with random issue categories
  def generate_request_issues(task, org)
    num_objects = rand(1..4)
    num_objects.times do
      create(:request_issue, :nonrating,
             nonrating_issue_category: Constants.ISSUE_CATEGORIES.vha.sample,
             decision_review: task.appeal, benefit_type: org.url)
    end
  end
end
