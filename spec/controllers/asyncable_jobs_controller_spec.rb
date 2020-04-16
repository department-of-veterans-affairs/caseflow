# frozen_string_literal: true

describe AsyncableJobsController, :postgres, type: :controller do
  before do
    User.stub = user
  end

  describe "#show" do
    context "User is not asyncable_user" do
      let(:user) { create(:default_user) }
      let!(:job) { create(:higher_level_review, intake: create(:intake)) }

      it "returns unauthorized" do
        get :show, params: { asyncable_job_klass: job.class.to_s, id: job.id }

        expect(response.status).to eq 302
        expect(response.body).to match(/unauthorized/)
      end
    end

    context "User is asyncable_user" do
      let(:user) { create(:default_user) }
      let!(:job) { create(:higher_level_review, intake: create(:intake, user: user)) }

      it "allows view" do
        get :show, params: { asyncable_job_klass: job.class.to_s, id: job.id }

        expect(response.status).to eq 200
      end
    end
  end

  describe "#index" do
    context "user is not Admin Intake or Manage Claim Establishment" do
      let(:user) { create(:default_user) }

      it "returns unauthorized" do
        get :index

        expect(response.status).to eq 302
        expect(response.body).to match(/unauthorized/)
      end
    end

    context "user is Global Admin" do
      before do
        allow(user).to receive(:admin?) { true }
      end

      let(:user) { create(:default_user) }
      let(:page_size) { 50 }
      let(:review) { create(:higher_level_review) }
      let(:many_jobs) do
        (1..page_size + 1).map do
          create(
            :request_issues_update,
            :requires_processing,
            user: user,
            review: review,
            before_request_issue_ids: [],
            after_request_issue_ids: []
          )
        end
      end

      it "allows access" do
        get :index

        expect(response.status).to eq 200
      end

      it "handles requests for CSV format" do
        get(:index, format: :csv)

        expect(response.status).to eq 200
        expect(response.headers["Content-Type"]).to include "text/csv"
        expect(response.body).to start_with("type,id,submitted,last_submitted,attempted,error,participant_id\n")
      end

      it "includes unpaginated jobs in CSV format" do
        many_jobs
        get(:index, format: :csv)

        records = response.body.strip.split("\n")[1..-1]
        expect(records.length).to be > page_size
      end
    end

    context "user is Manage Claim Establishment" do
      let(:user) { User.authenticate!(roles: ["Manage Claim Establishment"]) }

      it "allows access" do
        get :index

        expect(response.status).to eq 200
      end
    end

    context "user is Admin Intake" do
      let(:user) { User.authenticate!(roles: ["Admin Intake"]) }
      let(:veteran) { create(:veteran) }
      let!(:hlr) do
        create(:higher_level_review,
               establishment_submitted_at: 7.days.ago,
               establishment_attempted_at: 7.days.ago,
               veteran_file_number: veteran.file_number)
      end
      let!(:sc) do
        create(:supplemental_claim,
               establishment_submitted_at: 7.days.ago,
               establishment_attempted_at: 7.days.ago,
               veteran_file_number: veteran.file_number)
      end
      let!(:riu) do
        create(:request_issues_update, review: hlr, submitted_at: 7.days.ago, attempted_at: 7.days.ago)
      end
      let!(:request_issue) do
        create(:request_issue,
               decision_review: hlr,
               decision_sync_submitted_at: 7.days.ago,
               decision_sync_attempted_at: 7.days.ago)
      end
      let!(:bge) do
        create(:board_grant_effectuation,
               decision_sync_submitted_at: 7.days.ago,
               decision_sync_attempted_at: 7.days.ago)
      end
      let!(:decision_document) do
        create(:decision_document, submitted_at: 7.days.ago, attempted_at: 7.days.ago)
      end
      let!(:task_timer) do
        task = create(:ama_task)
        TaskTimer.create!(task: task, submitted_at: 7.days.ago, attempted_at: 7.days.ago)
      end

      context "no asyncable klass specified" do
        render_views

        it "renders table of all expired jobs" do
          get :index, as: :html

          expect(response.status).to eq 200
          expect(response.body).to match(/SupplementalClaim/)
          expect(response.body).to match(/HigherLevelReview/)
          expect(response.body).to match(/RequestIssuesUpdate/)
          expect(response.body).to match(/RequestIssue\b/)
          expect(response.body).to match(/BoardGrantEffectuation/)
          expect(response.body).to match(/TaskTimer/)
          expect(response.body).to match(/DecisionDocument/)
        end
      end

      context "asyncable klass specified" do
        render_views

        it "renders table limited to the klass" do
          get :index, as: :html, params: { asyncable_job_klass: "HigherLevelReview" }

          expect(response.status).to eq 200
          expect(response.body).to match(/"asyncableJobKlass":"HigherLevelReview"/)
        end
      end

      context "#pagination" do
        it "paginates based on asyncable_job_klass" do
          get :index, as: :html, params: { asyncable_job_klass: "HigherLevelReview" }

          expect(subject.send(:pagination)).to eq(total_pages: 1, total_items: 1, current_page: 1, page_size: 50)
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
