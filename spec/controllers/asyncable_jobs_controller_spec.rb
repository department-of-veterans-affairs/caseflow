# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe AsyncableJobsController, :postgres, type: :controller do
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
        task = create(:generic_task, :on_hold)
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

          expect(subject.send(:pagination)).to eq(total_pages: 1, total_jobs: 1, current_page: 1, page_size: 50)
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
