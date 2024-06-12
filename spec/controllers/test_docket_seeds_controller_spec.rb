# frozen_string_literal: true

RSpec.describe TestDocketSeedsController, :all_dbs, type: :controller do
  unless Rake::Task.task_defined?("assets:precompile")
    Rails.application.load_tasks
  end
  let!(:authenticated_user) { User.authenticate!(css_id: "RSPEC", roles: ["System Admin"]) }

  describe "POST run-demo?seed_type=ii?seed_count=x&days_ago=y&judge_css_id=zzz" do
    context "seed_ama_aod_hearings" do
      context "single seed" do
        context "with judge CSS ID given" do
          it "creates a 30 day old AMA AOD Hearing case" do
            post :seed_dockets, params: {
              seed_type: "ama-aod-hearing-seeds",
              seed_count: "1",
              days_ago: "30",
              judge_css_id: "RSPCJUDGE1"
            }

            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            hearing_case = Appeal.last
            expect(hearing_case.aod_based_on_age).to be_truthy
            expect(hearing_case.docket_type).to eq("hearing")
            expect(hearing_case.hearings.first.disposition).to eq("held")
            expect(hearing_case.hearings.first.judge.css_id).to eq("RSPCJUDGE1")
            expect(hearing_case.receipt_date).to eq(Date.parse(30.days.ago.to_s))
            expect(Date.parse(hearing_case.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(30.days.ago.to_s))
          end

          it "creates a 365 day old AMA AOD Hearing case" do
            post :seed_dockets, params: {
              seed_type: "ama-aod-hearing-seeds",
              seed_count: "1",
              days_ago: "365",
              judge_css_id: "RSPCJUDGE1"
            }

            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            hearing_case = Appeal.last
            expect(hearing_case.aod_based_on_age).to be_truthy
            expect(hearing_case.docket_type).to eq("hearing")
            expect(hearing_case.hearings.first.disposition).to eq("held")
            expect(hearing_case.hearings.first.judge.css_id).to eq("RSPCJUDGE1")
            expect(hearing_case.receipt_date).to eq(Date.parse(365.days.ago.to_s))
            expect(Date.parse(hearing_case.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(365.days.ago.to_s))
          end
        end

        context "without judge CSS ID given" do
          it "creates a 90 day old AMA AOD Hearing case" do
            post :seed_dockets, params: {
              seed_type: "ama-aod-hearing-seeds",
              seed_count: "1",
              days_ago: "90",
              judge_css_id: ""
            }

            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            hearing_case = Appeal.last
            expect(hearing_case.aod_based_on_age).to be_truthy
            expect(hearing_case.docket_type).to eq("hearing")
            expect(hearing_case.hearings.first.disposition).to eq("held")
            expect(hearing_case.hearings.first.judge.css_id).to eq("QDEMOSEEDJ")
            expect(hearing_case.receipt_date).to eq(Date.parse(90.days.ago.to_s))
            expect(Date.parse(hearing_case.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(90.days.ago.to_s))
          end

          it "creates a 730 day old AMA AOD Hearing case" do
            post :seed_dockets, params: {
              seed_type: "ama-aod-hearing-seeds",
              seed_count: "1",
              days_ago: "730",
              judge_css_id: ""
            }

            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            hearing_case = Appeal.last
            expect(hearing_case.aod_based_on_age).to be_truthy
            expect(hearing_case.docket_type).to eq("hearing")
            expect(hearing_case.hearings.first.disposition).to eq("held")
            expect(hearing_case.hearings.first.judge.css_id).to eq("QDEMOSEEDJ")
            expect(hearing_case.receipt_date).to eq(Date.parse(730.days.ago.to_s))
            expect(Date.parse(hearing_case.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(730.days.ago.to_s))
          end
        end
      end
      context "multiple seeds" do
        it "creates multiple AMA AOD Hearing cases" do
          post :seed_dockets, params: {
            seed_type: "ama-aod-hearing-seeds",
            seed_count: "5",
            days_ago: "300",
            judge_css_id: "Q5AODJUDGE"
          }

          expect(response.status).to eq 200
          expect(Appeal.count).to eq(5)
        end
      end
    end

    context "seed_ama_non_aod_hearings" do
      context "single seed" do
        context "with judge CSS ID given" do
          it "creates a 30 day old AMA non-AOD Hearing case" do
            post :seed_dockets, params: {
              seed_type: "ama-non-aod-hearing-seeds",
              seed_count: "1",
              days_ago: "30",
              judge_css_id: "RSPCJUDGE2"
            }

            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            hearing_case = Appeal.last
            expect(hearing_case.aod_based_on_age).to be_falsey
            expect(hearing_case.docket_type).to eq("hearing")
            expect(hearing_case.hearings.first.disposition).to eq("held")
            expect(hearing_case.hearings.first.judge.css_id).to eq("RSPCJUDGE2")
            expect(hearing_case.receipt_date).to eq(Date.parse(30.days.ago.to_s))
            expect(Date.parse(hearing_case.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(30.days.ago.to_s))
          end

          it "creates a 365 day old AMA non-AOD Hearing case" do
            post :seed_dockets, params: {
              seed_type: "ama-non-aod-hearing-seeds",
              seed_count: "1",
              days_ago: "365",
              judge_css_id: "RSPCJUDGE2"
            }

            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            hearing_case = Appeal.last
            expect(hearing_case.aod_based_on_age).to be_falsey
            expect(hearing_case.docket_type).to eq("hearing")
            expect(hearing_case.hearings.first.disposition).to eq("held")
            expect(hearing_case.hearings.first.judge.css_id).to eq("RSPCJUDGE2")
            expect(hearing_case.receipt_date).to eq(Date.parse(365.days.ago.to_s))
            expect(Date.parse(hearing_case.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(365.days.ago.to_s))
          end
        end

        context "without judge CSS ID given" do
          it "creates a 90 day old AMA non-AOD Hearing case" do
            post :seed_dockets, params: {
              seed_type: "ama-non-aod-hearing-seeds",
              seed_count: "1",
              days_ago: "90",
              judge_css_id: ""
            }

            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            hearing_case = Appeal.last
            expect(hearing_case.aod_based_on_age).to be_falsey
            expect(hearing_case.docket_type).to eq("hearing")
            expect(hearing_case.hearings.first.disposition).to eq("held")
            expect(hearing_case.hearings.first.judge.css_id).to eq("QDEMOSEEDJ")
            expect(hearing_case.receipt_date).to eq(Date.parse(90.days.ago.to_s))
            expect(Date.parse(hearing_case.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(90.days.ago.to_s))
          end

          it "creates a 730 day old AMA non-AOD Hearing case" do
            post :seed_dockets, params: {
              seed_type: "ama-non-aod-hearing-seeds",
              seed_count: "1",
              days_ago: "730",
              judge_css_id: ""
            }

            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            hearing_case = Appeal.last
            expect(hearing_case.aod_based_on_age).to be_falsey
            expect(hearing_case.docket_type).to eq("hearing")
            expect(hearing_case.hearings.first.disposition).to eq("held")
            expect(hearing_case.hearings.first.judge.css_id).to eq("QDEMOSEEDJ")
            expect(hearing_case.receipt_date).to eq(Date.parse(730.days.ago.to_s))
            expect(Date.parse(hearing_case.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(730.days.ago.to_s))
          end
        end
      end
      context "multiple seeds" do
        it "creates multiple AMA non-AOD Hearing cases" do
          post :seed_dockets, params: {
            seed_type: "ama-non-aod-hearing-seeds",
            seed_count: "5",
            days_ago: "180",
            judge_css_id: ""
          }

          expect(response.status).to eq 200
          expect(Appeal.count).to eq(5)
        end
      end
    end

    context "seed_legacy_cases" do
      context "single seed" do
        context "with judge CSS ID given" do
          it "creates a 30 day old Legacy case" do
            post :seed_dockets, params: {
              seed_type: "legacy-case-seeds",
              seed_count: "1",
              days_ago: "30",
              judge_css_id: "RSPCJUDGE3"
            }

            expect(response.status).to eq 200
            expect(LegacyAppeal.count).to eq(1)
            # legacy_appeal = LegacyAppeal.last
            # TODO: Add expext statements
          end

          it "creates a 365 day old Legacy case" do
            post :seed_dockets, params: {
              seed_type: "legacy-case-seeds",
              seed_count: "1",
              days_ago: "365",
              judge_css_id: "RSPCJUDGE3"
            }

            expect(response.status).to eq 200
            expect(LegacyAppeal.count).to eq(1)
            # legacy_appeal = LegacyAppeal.last
            # TODO: Add expext statements
          end
        end

        context "without judge CSS ID given" do
          it "creates a 90 day old Legacy case" do
            post :seed_dockets, params: {
              seed_type: "legacy-case-seeds",
              seed_count: "1",
              days_ago: "90",
              judge_css_id: ""
            }

            expect(response.status).to eq 200
            expect(LegacyAppeal.count).to eq(1)
            # legacy_appeal = LegacyAppeal.last
            # TODO: Add expext statements
          end

          it "creates a 730 day old Legacy case" do
            post :seed_dockets, params: {
              seed_type: "legacy-case-seeds",
              seed_count: "1",
              days_ago: "730",
              judge_css_id: ""
            }

            expect(response.status).to eq 200
            expect(LegacyAppeal.count).to eq(1)
            # legacy_appeal = LegacyAppeal.last
            # TODO: Add expext statements
          end
        end
      end
      context "multiple seeds" do
        it "creates multiple Legacy cases" do
          post :seed_dockets, params: {
            seed_type: "legacy-case-seeds",
            seed_count: "5",
            days_ago: "30",
            judge_css_id: ""
          }

          expect(response.status).to eq 200
          expect(LegacyAppeal.count).to eq(5)
        end
      end
    end

    context "seed_ama_direct_reviews" do
      context "single seed" do
        context "with judge CSS ID given" do
          it "creates a 30 day old Direct Review case" do
            post :seed_dockets, params: {
              seed_type: "ama-direct-review-seeds",
              seed_count: "1",
              days_ago: "30",
              judge_css_id: "RSPCJUDGE4"
            }

            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            direct_review = Appeal.last
            expect(direct_review.docket_type).to eq("direct_review")
            # expect(hearing_case.hearings.first.judge.css_id).to eq("RSPCJUDGE1")
            expect(direct_review.receipt_date).to eq(Date.parse(30.days.ago.to_s))
            expect(Date.parse(direct_review.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(30.days.ago.to_s))
          end

          it "creates a 365 day old Direct Review case" do
            post :seed_dockets, params: {
              seed_type: "ama-direct-review-seeds",
              seed_count: "1",
              days_ago: "365",
              judge_css_id: "RSPCJUDGE4"
            }

            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            direct_review = Appeal.last
            expect(direct_review.docket_type).to eq("direct_review")
            # expect(hearing_case.hearings.first.judge.css_id).to eq("RSPCJUDGE1")
            expect(direct_review.receipt_date).to eq(Date.parse(365.days.ago.to_s))
            expect(Date.parse(direct_review.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(365.days.ago.to_s))
          end
        end

        context "without judge CSS ID given" do
          it "creates a 90 day old Direct Review case" do
            post :seed_dockets, params: {
              seed_type: "ama-direct-review-seeds",
              seed_count: "1",
              days_ago: "90",
              judge_css_id: ""
            }

            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            direct_review = Appeal.last
            expect(direct_review.docket_type).to eq("direct_review")
            # expect(hearing_case.hearings.first.judge.css_id).to eq("RSPCJUDGE1")
            expect(direct_review.receipt_date).to eq(Date.parse(90.days.ago.to_s))
            expect(Date.parse(direct_review.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(90.days.ago.to_s))
          end

          it "creates a 730 day old Direct Review case" do
            post :seed_dockets, params: {
              seed_type: "ama-direct-review-seeds",
              seed_count: "1",
              days_ago: "730",
              judge_css_id: ""
            }

            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            direct_review = Appeal.last
            expect(direct_review.docket_type).to eq("direct_review")
            # expect(hearing_case.hearings.first.judge.css_id).to eq("RSPCJUDGE1")
            expect(direct_review.receipt_date).to eq(Date.parse(730.days.ago.to_s))
            expect(Date.parse(direct_review.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(730.days.ago.to_s))
          end
        end
      end
      context "multiple seeds" do
        it "creates multiple Direct Review cases" do
          post :seed_dockets, params: {
            seed_type: "ama-direct-review-seeds",
            seed_count: "5",
            days_ago: "30",
            judge_css_id: ""
          }

          expect(response.status).to eq 200
          expect(Appeal.where(docket_type: "direct_review").count).to eq(5)
          expect(Appeal.count).to eq(5)
        end
      end
    end
  end
end
