# frozen_string_literal: true

require "support/vacols_database_cleaner"

describe StatusSerializer, :all_dbs do
	context "status for appeals" do
		let(:judge) { create(:user) }
    let!(:hearings_user) { create(:hearings_coordinator) }
    let!(:receipt_date) { Constants::DATES["AMA_ACTIVATION_TEST"].to_date + 1 }
    let(:appeal) { create(:appeal, receipt_date: receipt_date) }
    let!(:appeal_root_task) { create(:root_task, :in_progress, appeal: appeal) }

    context "appeal not assigned" do
      it "is on docket" do
        status = StatusSerializer.new(appeal).serializable_hash[:data][:attributes]
        expect(status[:type]).to eq(:on_docket)
        expect(status[:details]).to be_empty
      end
    end

    context "hearing to be scheduled" do
      let!(:schedule_hearing_task) do
        create(:schedule_hearing_task, :in_progress, appeal: appeal, assigned_to: hearings_user)
      end

      it "is waiting for hearing to be scheduled" do
        status = StatusSerializer.new(appeal).serializable_hash[:data][:attributes]
        expect(status[:type]).to eq(:pending_hearing_scheduling)
        expect(status[:details][:type]).to eq("video")
      end
    end

    context "hearing is scheduled" do
      let(:hearing_task) { create(:hearing_task, parent: appeal_root_task, appeal: appeal) }
      let(:hearing_scheduled_for) { Time.zone.today + 15.days }
      let(:hearing_day) do
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               regional_office: "RO18",
               scheduled_for: hearing_scheduled_for)
      end

      let(:hearing) do
        create(
          :hearing,
          appeal: appeal,
          disposition: nil,
          evidence_window_waived: nil,
          hearing_day: hearing_day
        )
      end
      let!(:hearing_task_association) do
        create(
          :hearing_task_association,
          hearing: hearing,
          hearing_task: hearing_task
        )
      end
      let!(:schedule_hearing_task) do
        create(
          :schedule_hearing_task,
          :completed,
          parent: hearing_task,
          appeal: appeal
        )
      end
      let!(:disposition_task) do
        create(
          :assign_hearing_disposition_task,
          :in_progress,
          parent: hearing_task,
          appeal: appeal
        )
      end

      it "status is scheduled_hearing with hearing details" do
        status = StatusSerializer.new(appeal).serializable_hash[:data][:attributes]
        expect(status[:type]).to eq(:scheduled_hearing)
        expect(status[:details][:type]).to eq("video")
        expect(status[:details][:date]).to eq(hearing_scheduled_for.to_date)
        expect(status[:details][:location]).to be_nil
      end
    end

    context "in an evidence submission window" do
      let!(:schedule_hearing_task) do
        create(:schedule_hearing_task, :completed, appeal: appeal, assigned_to: hearings_user)
      end
      let!(:evidence_submission_task) do
        create(:evidence_submission_window_task, :in_progress, appeal: appeal, assigned_to: Bva.singleton)
      end
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task, :in_progress,
               assigned_to: judge, appeal: appeal)
      end

      it "is in evidentiary period " do
        status = StatusSerializer.new(appeal).serializable_hash[:data][:attributes]
        expect(status[:type]).to eq(:evidentiary_period)
        expect(status[:details]).to be_empty
      end
    end

    context "assigned to judge" do
      let!(:schedule_hearing_task) do
        create(:schedule_hearing_task, :completed, appeal: appeal, assigned_to: hearings_user)
      end
      let!(:evidence_submission_task) do
        create(:evidence_submission_window_task, :completed, appeal: appeal,
                                                             assigned_to: Bva.singleton)
      end
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task, :in_progress,
               assigned_to: judge, appeal: appeal)
      end

      it "waiting for a decision" do
        status = StatusSerializer.new(appeal).serializable_hash[:data][:attributes]
        expect(status[:type]).to eq(:decision_in_progress)
        expect(status[:details][:decision_timeliness]).to eq([1, 2])
      end
    end

    context "have a decision with no remands or effectuation, no decision document" do
      let!(:appeal_root_task) { create(:root_task, :completed, appeal: appeal) }
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task, :completed,
               assigned_to: judge, appeal: appeal)
      end
      let!(:not_remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal, disposition: "allowed")
      end

      it "status is still in progress since because no decision document" do
        status = StatusSerializer.new(appeal).serializable_hash[:data][:attributes]
        expect(status[:type]).to eq(:decision_in_progress)
        expect(status[:details][:decision_timeliness]).to eq([1, 2])
      end

      context "decision document created" do
        let!(:decision_document) { create(:decision_document, appeal: appeal) }

        it "status is bva_decision" do
          status =StatusSerializer.new(appeal).serializable_hash[:data][:attributes]
          expect(status[:type]).to eq(:bva_decision)
          expect(status[:details][:issues].first[:description]).to eq("Dental or oral condition")
          expect(status[:details][:issues].first[:disposition]).to eq("allowed")
        end
      end
    end

    context "has an effectuation" do
      let!(:appeal_root_task) { create(:root_task, :completed, appeal: appeal) }
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task, :completed,
               assigned_to: judge, appeal: appeal)
      end
      let!(:not_remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal, caseflow_decision_date: receipt_date + 60.days)
      end
      let(:decision_document) { create(:decision_document, appeal: appeal) }
      let(:ep_status) { "CLR" }
      let!(:effectuation_ep) do
        create(:end_product_establishment,
               source: decision_document, synced_status: ep_status, last_synced_at: receipt_date + 100.days)
      end

      it "effectuation had an ep" do
        status = StatusSerializer.new(appeal).serializable_hash[:data][:attributes]
        expect(status[:type]).to eq(:bva_decision_effectuation)
        expect(status[:details][:bva_decision_date].to_date).to eq((receipt_date + 60.days).to_date)
        expect(status[:details][:aoj_decision_date].to_date).to eq((receipt_date + 100.days).to_date)
      end
    end

    context "has an active remand" do
      let!(:appeal_root_task) { create(:root_task, :completed, appeal: appeal) }
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task, :completed,
               assigned_to: judge, appeal: appeal)
      end
      let!(:not_remanded_decision_issue) { create(:decision_issue, decision_review: appeal) }
      let!(:remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal,
               disposition: "remanded",
               benefit_type: "nca",
               diagnostic_code: nil,
               caseflow_decision_date: 1.day.ago)
      end

      it "it has status ama_remand" do
        appeal.create_remand_supplemental_claims!
        appeal.remand_supplemental_claims.each(&:reload)
        status = StatusSerializer.new(appeal).serializable_hash[:data][:attributes]
        expect(status[:type]).to eq(:ama_remand)
        expect(status[:details][:issues].count).to eq(2)
      end
    end

    context "has multiple remands" do
      let!(:appeal_root_task) { create(:root_task, :completed, appeal: appeal) }
      let!(:judge_review_task) do
        create(:ama_judge_decision_review_task, :completed,
               assigned_to: judge, appeal: appeal)
      end
      let!(:not_remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal, caseflow_decision_date: receipt_date + 60.days)
      end
      let!(:remanded_issue) do
        create(:decision_issue,
               decision_review: appeal,
               disposition: "remanded",
               benefit_type: "nca",
               caseflow_decision_date: receipt_date + 60.days)
      end
      let!(:remanded_issue_with_ep) do
        create(:decision_issue,
               decision_review: appeal,
               disposition: "remanded",
               benefit_type: "compensation",
               diagnostic_code: "9912",
               caseflow_decision_date: receipt_date + 60.days)
      end
      let!(:remanded_sc) do
        create(
          :supplemental_claim,
          veteran_file_number: appeal.veteran_file_number,
          decision_review_remanded: appeal,
          benefit_type: remanded_issue.benefit_type
        )
      end
      let!(:remanded_sc_decision) do
        create(:decision_issue,
               decision_review: remanded_sc,
               disposition: "granted",
               diagnostic_code: "9915",
               caseflow_decision_date: receipt_date + 101.days)
      end
      let!(:remanded_sc_with_ep) do
        create(
          :supplemental_claim,
          veteran_file_number: appeal.veteran_file_number,
          decision_review_remanded: appeal,
          benefit_type: remanded_issue_with_ep.benefit_type
        )
      end
      let!(:remanded_ep) do
        create(:end_product_establishment,
               :cleared, source: remanded_sc_with_ep, last_synced_at: receipt_date + 100.days)
      end
      let!(:remanded_sc_with_ep_decision) do
        create(:decision_issue,
               decision_review: remanded_sc_with_ep,
               disposition: "denied",
               diagnostic_code: "9912",
               end_product_last_action_date: receipt_date + 100.days)
      end

      context "they are all complete" do
        let!(:remanded_sc_task) { create(:task, :completed, appeal: remanded_sc) }
        it "has post_bva_dta_decision status,shows the latest decision date, and remand dedision issues" do
          status = StatusSerializer.new(appeal).serializable_hash[:data][:attributes]
          expect(status[:type]).to eq(:post_bva_dta_decision)
          expect(status[:details][:issues]).to include(
            { description: "Partial loss of upper jaw", disposition: "granted" },
            description: "Partial loss of hard palate", disposition: "denied"
          )
          expect(status[:details][:bva_decision_date]).to eq((receipt_date + 60.days).to_date)
          expect(status[:details][:aoj_decision_date]).to eq((receipt_date + 101.days).to_date)
        end
      end

      context "they are not all complete" do
        let!(:remanded_sc_task) { create(:task, :in_progress, appeal: remanded_sc) }
        it "has ama_remand status, no decision dates, and shows appeals decision issues" do
          status = StatusSerializer.new(appeal).serializable_hash[:data][:attributes]
          expect(status[:type]).to eq(:ama_remand)
          expect(status[:details][:issues]).to include(
            { description: "Dental or oral condition", disposition: "allowed" },
            { description: "Partial loss of hard palate", disposition: "remanded" },
            description: "Partial loss of hard palate", disposition: "remanded"
          )
          expect(status[:details][:bva_decision_date]).to be_nil
          expect(status[:details][:aoj_decision_date]).to be_nil
        end
      end
    end
	end

  context "status for higher level review" do
    let(:receipt_date) { Time.new("2018", "03", "01").utc }
    let(:benefit_type) { "compensation" }
    let(:hlr_decision_date) { receipt_date + 30.days }

    let!(:hlr) do
      create(:higher_level_review,
             receipt_date: receipt_date,
             benefit_type: benefit_type)
    end

    context "has a decision" do
      let!(:request_issue1) do
        create(:request_issue,
               decision_review: hlr,
               benefit_type: benefit_type,
               contested_rating_issue_diagnostic_code: "8877")
      end

      let!(:hlr_ep) do
        create(:end_product_establishment,
               :cleared,
               source: hlr,
               last_synced_at: hlr_decision_date)
      end

      let!(:hlr_decision_issue) do
        create(:decision_issue,
               decision_review: hlr,
               disposition: "denied",
               benefit_type: benefit_type,
               end_product_last_action_date: hlr_decision_date,
               diagnostic_code: "8877")
      end

      it "has decision status and status details" do
        status = StatusSerializer.new(hlr).serializable_hash[:data][:attributes]
        expect(status[:type]).to eq(:hlr_decision)
        expect(status[:details][:issues].first[:description]).to eq("Undiagnosed hemic or lymphatic condition")
        expect(status[:details][:issues].first[:disposition]).to eq("denied")
      end
    end

    context "dta error" do
      let(:receipt_date) { Time.new("2018", "03", "01").utc }
      let(:benefit_type) { "compensation" }
      let!(:hlr) do
        create(:higher_level_review,
               receipt_date: receipt_date,
               benefit_type: benefit_type)
      end

      let(:hlr_decision_date) { receipt_date + 30.days }

      let!(:hlr_decision_issue_with_dta_error) do
        create(:decision_issue,
               decision_review: hlr,
               disposition: DecisionIssue::DTA_ERROR_PMR,
               benefit_type: benefit_type,
               end_product_last_action_date: hlr_decision_date,
               diagnostic_code: "9999")
      end

      let!(:dta_sc) do
        create(:supplemental_claim,
               decision_review_remanded: hlr)
      end

      let!(:dta_ep) do
        create(:end_product_establishment,
               :cleared,
               source: dta_sc)
      end

      let!(:dta_request_issue) do
        create(:request_issue,
               decision_review: dta_sc,
               benefit_type: benefit_type,
               contested_rating_issue_diagnostic_code: "9999")
      end

      let(:dta_sc_decision_date) { receipt_date + 60.days }

      let!(:dta_sc_decision_issue) do
        create(:decision_issue,
               decision_review: dta_sc,
               disposition: "allowed",
               benefit_type: benefit_type,
               end_product_last_action_date: dta_sc_decision_date,
               diagnostic_code: "9999")
      end

      it "has decision status and status details for the dta sc decision" do
        status = StatusSerializer.new(hlr).serializable_hash[:data][:attributes]

        expect(status[:type]).to eq(:hlr_decision)
        expect(status[:details][:issues].first[:description]).to eq("Dental or oral condition")
        expect(status[:details][:issues].first[:disposition]).to eq("allowed")
      end
    end
  end

  context "status for supplemental claim" do
    let(:receipt_date) { Time.new("2018", "03", "01").utc }
    let(:benefit_type) { "compensation" }

    let(:sc) do
      create(:supplemental_claim, 
             receipt_date: receipt_date,
             benefit_type: benefit_type)
    end

    let(:ep_status) { "PEND" }
    let!(:sc_ep) do
      create(:end_product_establishment,
             synced_status: ep_status, source: sc)
    end

    context "SC received" do
      it "has status sc_recieved" do
        status = StatusSerializer.new(sc).serializable_hash[:data][:attributes]
        expect(status).to_not be_nil
        expect(status[:type]).to eq(:sc_recieved)
        expect(status[:details]).to be_empty
      end
    end

    context "SC gets a decision" do
      let(:ep_status) { "CLR" }

      let!(:decision_issue) do
        create(:decision_issue,
               decision_review: sc, end_product_last_action_date: receipt_date + 100.days,
               benefit_type: benefit_type, diagnostic_code: nil, disposition: "allowed")
      end

      it "has status sc_decision" do
        status = StatusSerializer.new(sc).serializable_hash[:data][:attributes]
        expect(status).to_not be_nil
        expect(status[:type]).to eq(:sc_decision)
        expect(status[:details][:issues].first[:description]).to eq("Compensation issue")
        expect(status[:details][:issues].first[:disposition]).to eq("allowed")
      end
    end
  end
end
