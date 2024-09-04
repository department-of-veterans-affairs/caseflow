# frozen_string_literal: true

TEST_SEEDS = JSON.parse(File.read("client/constants/TEST_SEEDS.json"))

RSpec.describe TestDocketSeedsController, :all_dbs, type: :controller do
  unless Rake::Task.task_defined?("assets:precompile")
    Rails.application.load_tasks
  end
  let!(:authenticated_user) { User.authenticate!(css_id: "RSPEC", roles: ["System Admin"]) }

  let(:root_task) { create(:root_task) }
  let(:distribution_task) do
    DistributionTask.create!(
      appeal: root_task.appeal,
      assigned_to: Bva.singleton,
      status: "assigned"
    )
  end

  let(:bfcurloc_keys) { %w[77 81 83] }
  let!(:cases) do
    bfcurloc_keys.map do |bfcurloc_key|
      create(:case, bfcurloc: bfcurloc_key)
    end
  end

  describe "POST run-demo?seed_type=ii?seed_count=x&days_ago=y&judge_css_id=zzz" do
    before(:all) do
      Rake::Task.define_task(:environment)
    end

    context "seed_ama_aod_hearings" do
      context "single seed" do
        context "with judge CSS ID given" do
          it "creates a 30 day old AMA AOD Hearing case" do
            data = [
              {
                seed_type: "ama-aod-hearing-seeds",
                seed_count: "1",
                days_ago: "30",
                judge_css_id: "TEST30JUDGE"
              }
            ]

            post :seed_dockets, body: data.to_json, as: :json
            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            hearing_case = Appeal.last
            expect(hearing_case.aod_based_on_age).to be_truthy
            expect(hearing_case.docket_type).to eq("hearing")
            expect(hearing_case.hearings.first.disposition).to eq("held")
            expect(hearing_case.hearings.first.judge.css_id).to eq("TEST30JUDGE")
            expect(hearing_case.receipt_date).to eq(Date.parse(30.days.ago.to_s))
            expect(Date.parse(hearing_case.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(30.days.ago.to_s))
          end

          it "creates a 365 day old AMA AOD Hearing case" do
            data = [
              {
                seed_type: "ama-aod-hearing-seeds",
                seed_count: "1",
                days_ago: "365",
                judge_css_id: "TEST365JUDGE"
              }
            ]

            post :seed_dockets, body: data.to_json, as: :json
            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            hearing_case = Appeal.last
            expect(hearing_case.aod_based_on_age).to be_truthy
            expect(hearing_case.docket_type).to eq("hearing")
            expect(hearing_case.hearings.first.disposition).to eq("held")
            expect(hearing_case.hearings.first.judge.css_id).to eq("TEST365JUDGE")
            expect(hearing_case.receipt_date).to eq(Date.parse(365.days.ago.to_s))
            expect(Date.parse(hearing_case.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(365.days.ago.to_s))
          end
        end

        context "without judge CSS ID given" do
          it "creates a 90 day old AMA AOD Hearing case" do
            data = [
              {
                seed_type: "ama-aod-hearing-seeds",
                seed_count: "1",
                days_ago: "90",
                judge_css_id: ""
              }
            ]

            post :seed_dockets, body: data.to_json, as: :json
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
            data = [
              {
                seed_type: "ama-aod-hearing-seeds",
                seed_count: "1",
                days_ago: "730",
                judge_css_id: ""
              }
            ]

            post :seed_dockets, body: data.to_json, as: :json
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
        it "creates multiple AMA AOD Hearing cases with a single judge" do
          data = [
            {
              seed_type: "ama-aod-hearing-seeds",
              seed_count: "5",
              days_ago: "300",
              judge_css_id: "TEST300JUDGE"
            }
          ]

          post :seed_dockets, body: data.to_json, as: :json
          expect(response.status).to eq 200
          expect(Appeal.count).to eq(5)
        end

        it "creates multiple AMA AOD Hearing cases with a different judges" do
          data = [
            {
              seed_type: "ama-aod-hearing-seeds",
              seed_count: "5",
              days_ago: "300",
              judge_css_id: "TEST300JUDGE"
            },
            {
              seed_type: "ama-aod-hearing-seeds",
              seed_count: "5",
              days_ago: "200",
              judge_css_id: "TEST200JUDGE"
            }
          ]

          post :seed_dockets, body: data.to_json, as: :json
          expect(response.status).to eq 200
          expect(Appeal.count).to eq(10)
        end
      end
    end

    context "seed_ama_non_aod_hearings" do
      context "single seed" do
        context "with judge CSS ID given" do
          it "creates a 30 day old AMA non-AOD Hearing case" do
            data = [
              {
                seed_type: "ama-non-aod-hearing-seeds",
                seed_count: "1",
                days_ago: "30",
                judge_css_id: "TEST30JUDGE"
              }
            ]

            post :seed_dockets, body: data.to_json, as: :json
            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            hearing_case = Appeal.last
            expect(hearing_case.aod_based_on_age).to be_falsey
            expect(hearing_case.docket_type).to eq("hearing")
            expect(hearing_case.hearings.first.disposition).to eq("held")
            expect(hearing_case.hearings.first.judge.css_id).to eq("TEST30JUDGE")
            expect(hearing_case.receipt_date).to eq(Date.parse(30.days.ago.to_s))
            expect(Date.parse(hearing_case.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(30.days.ago.to_s))
          end

          it "creates a 365 day old AMA non-AOD Hearing case" do
            data = [
              {
                seed_type: "ama-non-aod-hearing-seeds",
                seed_count: "1",
                days_ago: "365",
                judge_css_id: "TEST365JUDGE"
              }
            ]

            post :seed_dockets, body: data.to_json, as: :json
            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            hearing_case = Appeal.last
            expect(hearing_case.aod_based_on_age).to be_falsey
            expect(hearing_case.docket_type).to eq("hearing")
            expect(hearing_case.hearings.first.disposition).to eq("held")
            expect(hearing_case.hearings.first.judge.css_id).to eq("TEST365JUDGE")
            expect(hearing_case.receipt_date).to eq(Date.parse(365.days.ago.to_s))
            expect(Date.parse(hearing_case.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(365.days.ago.to_s))
          end
        end

        context "without judge CSS ID given" do
          it "creates a 90 day old AMA non-AOD Hearing case" do
            data = [
              {
                seed_type: "ama-non-aod-hearing-seeds",
                seed_count: "1",
                days_ago: "90",
                judge_css_id: ""
              }
            ]

            post :seed_dockets, body: data.to_json, as: :json
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
            data = [
              {
                seed_type: "ama-non-aod-hearing-seeds",
                seed_count: "1",
                days_ago: "730",
                judge_css_id: ""
              }
            ]

            post :seed_dockets, body: data.to_json, as: :json
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
          data = [
            {
              seed_type: "ama-non-aod-hearing-seeds",
              seed_count: "5",
              days_ago: "180",
              judge_css_id: ""
            }
          ]

          post :seed_dockets, body: data.to_json, as: :json
          expect(response.status).to eq 200
          expect(Appeal.count).to eq(5)
        end

        it "creates multiple AMA non-AOD Hearing cases with different judges" do
          data = [
            {
              seed_type: "ama-non-aod-hearing-seeds",
              seed_count: "5",
              days_ago: "180",
              judge_css_id: ""
            },
            {
              seed_type: "ama-non-aod-hearing-seeds",
              seed_count: "5",
              days_ago: "270",
              judge_css_id: "TEST270JUDGE"
            }
          ]

          post :seed_dockets, body: data.to_json, as: :json
          expect(response.status).to eq 200
          expect(Appeal.count).to eq(10)
        end
      end
    end

    context "seed_legacy_cases" do
      context "single seed" do
        context "with judge CSS ID given" do
          it "creates a 30 day old Legacy case" do
            data = [
              {
                seed_type: "legacy-case-seeds",
                seed_count: "1",
                days_ago: "30",
                judge_css_id: "TEST30JUDGE"
              }
            ]

            post :seed_dockets, body: data.to_json, as: :json
            expect(response.status).to eq 200
            expect(LegacyAppeal.count).to eq(1)
          end

          it "creates a 365 day old Legacy case" do
            data = [
              {
                seed_type: "legacy-case-seeds",
                seed_count: "1",
                days_ago: "365",
                judge_css_id: "TEST365JUDGE"
              }
            ]

            post :seed_dockets, body: data.to_json, as: :json
            expect(response.status).to eq 200
            expect(LegacyAppeal.count).to eq(1)
          end
        end

        context "without judge CSS ID given" do
          it "creates a 90 day old Legacy case" do
            data = [
              {
                seed_type: "legacy-case-seeds",
                seed_count: "1",
                days_ago: "90",
                judge_css_id: ""
              }
            ]

            post :seed_dockets, body: data.to_json, as: :json
            expect(response.status).to eq 200
            expect(LegacyAppeal.count).to eq(1)
          end

          it "creates a 730 day old Legacy case" do
            data = [
              {
                seed_type: "legacy-case-seeds",
                seed_count: "1",
                days_ago: "730",
                judge_css_id: ""
              }
            ]

            post :seed_dockets, body: data.to_json, as: :json
            expect(response.status).to eq 200
            expect(LegacyAppeal.count).to eq(1)
          end
        end
      end
      context "multiple seeds" do
        it "creates multiple Legacy cases" do
          data = [
            {
              seed_type: "legacy-case-seeds",
              seed_count: "5",
              days_ago: "30",
              judge_css_id: ""
            }
          ]

          post :seed_dockets, body: data.to_json, as: :json
          expect(response.status).to eq 200
          expect(LegacyAppeal.count).to eq(5)
        end

        it "creates multiple Legacy cases with multiple judges" do
          data = [
            {
              seed_type: "legacy-case-seeds",
              seed_count: "5",
              days_ago: "30",
              judge_css_id: ""
            },
            {
              seed_type: "legacy-case-seeds",
              seed_count: "5",
              days_ago: "60",
              judge_css_id: "TEST60JUDGE"
            }
          ]

          post :seed_dockets, body: data.to_json, as: :json
          expect(response.status).to eq 200
          expect(LegacyAppeal.count).to eq(10)
        end
      end
    end

    context "seed_ama_direct_reviews" do
      context "single seed" do
        context "with judge CSS ID given" do
          it "creates a 30 day old Direct Review case" do
            data = [
              {
                seed_type: "ama-direct-review-seeds",
                seed_count: "1",
                days_ago: "30",
                judge_css_id: ""
              }
            ]

            post :seed_dockets, body: data.to_json, as: :json
            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            direct_review = Appeal.last
            expect(direct_review.docket_type).to eq("direct_review")
            expect(direct_review.receipt_date).to eq(Date.parse(30.days.ago.to_s))
            expect(Date.parse(direct_review.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(30.days.ago.to_s))
          end

          it "creates a 365 day old Direct Review case" do
            data = [
              {
                seed_type: "ama-direct-review-seeds",
                seed_count: "1",
                days_ago: "365",
                judge_css_id: ""
              }
            ]

            post :seed_dockets, body: data.to_json, as: :json
            expect(response.status).to eq 200
            expect(Appeal.count).to eq(1)
            direct_review = Appeal.last
            expect(direct_review.docket_type).to eq("direct_review")
            expect(direct_review.receipt_date).to eq(Date.parse(365.days.ago.to_s))
            expect(Date.parse(direct_review.tasks.where(type: "DistributionTask").first.assigned_at.to_s))
              .to eq(Date.parse(365.days.ago.to_s))
          end
        end
      end

      context "multiple seeds" do
        it "creates multiple Direct Review cases" do
          data = [
            {
              seed_type: "ama-direct-review-seeds",
              seed_count: "5",
              days_ago: "30",
              judge_css_id: ""
            }
          ]

          post :seed_dockets, body: data.to_json, as: :json
          expect(response.status).to eq 200
          expect(Appeal.where(docket_type: "direct_review").count).to eq(5)
          expect(Appeal.count).to eq(5)
        end

        it "creates multiple Direct Review cases with multiple lines" do
          data = [
            {
              seed_type: "ama-direct-review-seeds",
              seed_count: "5",
              days_ago: "60",
              judge_css_id: ""
            },
            {
              seed_type: "ama-direct-review-seeds",
              seed_count: "5",
              days_ago: "90",
              judge_css_id: ""
            }
          ]

          post :seed_dockets, body: data.to_json, as: :json
          expect(response.status).to eq 200
          expect(Appeal.where(docket_type: "direct_review").count).to eq(10)
          expect(Appeal.count).to eq(10)
        end
      end
    end

    context "multiple case types" do
      context "a single seed of each type" do
        it "makes all seeds" do
          data = [
            {
              seed_type: "ama-aod-hearing-seeds",
              seed_count: "1",
              days_ago: "10",
              judge_css_id: ""
            },
            {
              seed_type: "ama-non-aod-hearing-seeds",
              seed_count: "1",
              days_ago: "15",
              judge_css_id: ""
            },
            {
              seed_type: "legacy-case-seeds",
              seed_count: "1",
              days_ago: "20",
              judge_css_id: ""
            },
            {
              seed_type: "ama-direct-review-seeds",
              seed_count: "1",
              days_ago: "25",
              judge_css_id: ""
            }
          ]

          post :seed_dockets, body: data.to_json, as: :json
          expect(response.status).to eq 200
          expect(Appeal.count).to eq(3)
          expect(Appeal.where(docket_type: "hearing", aod_based_on_age: true).count).to eq(1)
          expect(Appeal.where(docket_type: "hearing", aod_based_on_age: nil).count).to eq(1)
          expect(LegacyAppeal.count).to eq(1)
          expect(Appeal.where(docket_type: "direct_review").count).to eq(1)
        end
      end

      context "a multiple seeds of each type" do
        it "makes all seeds" do
          data = [
            {
              seed_type: "ama-aod-hearing-seeds",
              seed_count: "2",
              days_ago: "10",
              judge_css_id: ""
            },
            {
              seed_type: "ama-non-aod-hearing-seeds",
              seed_count: "3",
              days_ago: "15",
              judge_css_id: ""
            },
            {
              seed_type: "legacy-case-seeds",
              seed_count: "4",
              days_ago: "20",
              judge_css_id: ""
            },
            {
              seed_type: "ama-direct-review-seeds",
              seed_count: "5",
              days_ago: "25",
              judge_css_id: ""
            }
          ]

          post :seed_dockets, body: data.to_json, as: :json
          expect(response.status).to eq 200
          expect(Appeal.count).to eq(10)
          expect(Appeal.where(docket_type: "hearing", aod_based_on_age: true).count).to eq(2)
          expect(Appeal.where(docket_type: "hearing", aod_based_on_age: nil).count).to eq(3)
          expect(LegacyAppeal.count).to eq(4)
          expect(Appeal.where(docket_type: "direct_review").count).to eq(5)
        end
      end

      context "a multiple seeds of each type with given judges" do
        it "makes all seeds" do
          data = [
            {
              seed_type: "ama-aod-hearing-seeds",
              seed_count: "1",
              days_ago: "10",
              judge_css_id: "TEST10JUDGE"
            },
            {
              seed_type: "ama-non-aod-hearing-seeds",
              seed_count: "1",
              days_ago: "15",
              judge_css_id: "TEST15JUDGE"
            },
            {
              seed_type: "legacy-case-seeds",
              seed_count: "1",
              days_ago: "20",
              judge_css_id: "TEST20JUDGE"
            },
            {
              seed_type: "ama-direct-review-seeds",
              seed_count: "1",
              days_ago: "25",
              judge_css_id: ""
            }
          ]

          post :seed_dockets, body: data.to_json, as: :json
          expect(response.status).to eq 200
          expect(Appeal.count).to eq(3)
          expect(Appeal.where(docket_type: "hearing", aod_based_on_age: true).count).to eq(1)
          expect(Appeal.where(docket_type: "hearing", aod_based_on_age: nil).count).to eq(1)
          expect(LegacyAppeal.count).to eq(1)
          expect(Appeal.where(docket_type: "direct_review").count).to eq(1)
        end
      end
    end

    it "should reset all appeals" do
      expect(distribution_task.status).to eq("assigned")
      expect(VACOLS::Case.where(bfcurloc: %w[81 83]).count).to eq(2)
      expect(VACOLS::Case.where(bfcurloc: "testing").count).to eq(0)
      get :reset_all_appeals
      expect(response.status).to eq 200
      expect(distribution_task.reload.status).to eq("on_hold")
      expect(VACOLS::Case.where(bfcurloc: %w[81 83]).count).to eq(0)
      expect(VACOLS::Case.where(bfcurloc: "testing").count).to eq(2)
    end

    context "check environment when non prod environments is true" do
      before { allow(Rails).to receive(:deploy_env?).with(:demo).and_return(true) }

      it "allows access without redirecting" do
        get :reset_all_appeals
        expect(response.status).to eq 200
      end
    end

    context "check environment when in other environments" do
      before { allow(Rails).to receive(:deploy_env?).and_return(false) }

      it "redirects to /unauthorized" do
        get :reset_all_appeals
        expect(response).to redirect_to("/unauthorized")
      end
    end
  end
end
