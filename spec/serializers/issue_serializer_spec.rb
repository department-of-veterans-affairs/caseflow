# frozen_string_literal: true

describe IssueSerializer, :all_dbs do
  def issues_hash(object)
    IssueSerializer.new(object, is_collection: true).serializable_hash[:data].collect { |issue| issue[:attributes] }
  end

  context "#appeal" do
    let(:receipt_date) { ama_test_start_date + 1 }

    let(:request_issue1) do
      create(:request_issue,
             benefit_type: "compensation", contested_rating_issue_diagnostic_code: "5002",
             contested_issue_description: "Contested issue description")
    end

    let(:request_issue2) do
      create(:request_issue, :nonrating,
             benefit_type: "pension", contested_rating_issue_diagnostic_code: nil)
    end

    let!(:appeal) do
      create(:appeal, receipt_date: receipt_date,
                      request_issues: [request_issue1, request_issue2])
    end

    let!(:root_task) { create(:root_task, :in_progress, appeal: appeal) }

    context "appeal pending a decision" do
      it "is status of the request issues" do
        issue_statuses = issues_hash(appeal.active_request_issues_or_decision_issues)

        expect(issue_statuses.count).to eq(2)

        issue = issue_statuses.find { |i| i[:diagnosticCode] == "5002" }
        expect(issue).to_not be_nil
        expect(issue[:active]).to eq(true)
        expect(issue[:lastAction]).to be_nil
        expect(issue[:date]).to be_nil
        expect(issue[:description]).to eq("Rheumatoid arthritis")

        issue2 = issue_statuses.find { |i| i[:diagnosticCode].nil? }
        expect(issue2).to_not be_nil
        expect(issue2[:active]).to eq(true)
        expect(issue2[:lastAction]).to be_nil
        expect(issue2[:date]).to be_nil
        expect(issue2[:description]).to eq("Pension issue")
      end

      context "with appeal_status_api_full_issue_description enabled" do
        before { FeatureToggle.enable!(:appeals_status_api_full_issue_description) }
        after { FeatureToggle.disable!(:appeals_status_api_full_issue_description) }

        it "gives the full request issue description" do
          issue_statuses = issues_hash(appeal.active_request_issues_or_decision_issues)

          issue = issue_statuses.find { |i| i[:diagnosticCode] == "5002" }
          expect(issue[:description]).to eq(request_issue1.contested_issue_description)

          issue2 = issue_statuses.find { |i| i[:diagnosticCode].nil? }
          expect(issue2[:description])
            .to eq("#{request_issue2.nonrating_issue_category} - #{request_issue2.nonrating_issue_description}")
        end
      end
    end

    context "have decisions, one is remanded" do
      let!(:decision_date) { receipt_date + 130.days }
      let!(:decision_document) { create(:decision_document, appeal: appeal, decision_date: decision_date) }

      let!(:not_remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal, benefit_type: "pension", disposition: "allowed",
               diagnostic_code: nil,
               caseflow_decision_date: decision_date)
      end

      let!(:remanded_issue_with_ep) do
        create(:decision_issue,
               decision_review: appeal, disposition: "remanded", benefit_type: "compensation",
               diagnostic_code: "5002", caseflow_decision_date: decision_date)
      end

      let(:remanded_sc) { create(:supplemental_claim, decision_review_remanded: appeal) }
      let!(:remanded_ep) { create(:end_product_establishment, source: remanded_sc, synced_status: "PEND") }

      it "remanded decision as active, other decision as inactive" do
        issue_statuses = issues_hash(appeal.active_request_issues_or_decision_issues)

        expect(issue_statuses.empty?).to eq(false)

        issue = issue_statuses.find { |i| i[:diagnosticCode] == "5002" }
        expect(issue).to_not be_nil
        expect(issue[:active]).to eq(true)
        expect(issue[:lastAction]).to eq("remand")
        expect(issue[:date].to_date).to eq(decision_date.to_date)
        expect(issue[:description]).to eq("Rheumatoid arthritis")

        issue2 = issue_statuses.find { |i| i[:diagnosticCode].nil? }
        expect(issue2).to_not be_nil
        expect(issue2[:active]).to eq(false)
        expect(issue2[:lastAction]).to eq("allowed")
        expect(issue2[:date].to_date).to eq(decision_date.to_date)
        expect(issue2[:description]).to eq("Pension issue")
      end

      context "with appeal_status_api_full_issue_description enabled" do
        before { FeatureToggle.enable!(:appeals_status_api_full_issue_description) }
        after { FeatureToggle.disable!(:appeals_status_api_full_issue_description) }

        it "gives the full decision issue description" do
          issue_statuses = issues_hash(appeal.active_request_issues_or_decision_issues)

          issue = issue_statuses.find { |i| i[:diagnosticCode] == "5002" }
          expect(issue[:description]).to eq(remanded_issue_with_ep.description)

          issue2 = issue_statuses.find { |i| i[:diagnosticCode].nil? }
          expect(issue2[:description]).to eq(not_remanded_decision_issue.description)
        end
      end
    end

    context "remanded sc has decision" do
      let!(:decision_date) { receipt_date + 130.days }
      let!(:decision_document) { create(:decision_document, appeal: appeal, decision_date: decision_date) }

      let!(:not_remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal, benefit_type: "pension", disposition: "allowed",
               diagnostic_code: nil,
               caseflow_decision_date: decision_date)
      end
      let!(:remanded_issue_with_ep) do
        create(:decision_issue,
               decision_review: appeal, disposition: "remanded", benefit_type: "compensation",
               diagnostic_code: "5002", caseflow_decision_date: decision_date)
      end
      let(:remanded_sc) { create(:supplemental_claim, decision_review_remanded: appeal) }
      let!(:remanded_ep) { create(:end_product_establishment, source: remanded_sc, synced_status: "CLR") }
      let(:remand_sc_decision_date) { decision_date + 30.days }

      let!(:remanded_sc_decision) do
        create(:decision_issue,
               decision_review: remanded_sc, disposition: "denied", benefit_type: "compensation",
               diagnostic_code: "5002", end_product_last_action_date: remand_sc_decision_date)
      end

      it "has the remand sc decision and other decision" do
        issue_statuses = issues_hash(appeal.active_request_issues_or_decision_issues)

        expect(issue_statuses.empty?).to eq(false)
        issue = issue_statuses.find { |i| i[:diagnosticCode] == "5002" }
        expect(issue).to_not be_nil
        expect(issue[:active]).to eq(false)
        expect(issue[:lastAction]).to eq("denied")
        expect(issue[:date].to_date).to eq(remand_sc_decision_date.to_date)
        expect(issue[:description]).to eq("Rheumatoid arthritis")

        issue2 = issue_statuses.find { |i| i[:diagnosticCode].nil? }
        expect(issue2).to_not be_nil
        expect(issue2[:active]).to eq(false)
        expect(issue2[:lastAction]).to eq("allowed")
        expect(issue2[:date].to_date).to eq(decision_date.to_date)
        expect(issue2[:description]).to eq("Pension issue")
      end
    end
  end

  context "#higher_level_review" do
    let(:receipt_date) { Time.new("2018", "03", "01").utc }
    let(:benefit_type) { "compensation" }

    let(:ep_status) { "PEND" }
    let!(:hlr_ep) do
      create(:end_product_establishment,
             synced_status: ep_status,
             source: hlr,
             last_synced_at: receipt_date + 100.days)
    end

    let!(:request_issue1) do
      create(:request_issue,
             decision_review: hlr,
             benefit_type: benefit_type,
             contested_rating_issue_diagnostic_code: "9999",
             contested_issue_description: "Contested issue description 1")
    end

    let!(:request_issue2) do
      create(:request_issue,
             decision_review: hlr,
             benefit_type: benefit_type,
             contested_rating_issue_diagnostic_code: "8877",
             contested_issue_description: "Contested issue description 2")
    end

    let!(:hlr) do
      create(:higher_level_review,
             receipt_date: receipt_date,
             benefit_type: benefit_type)
    end

    context "claim open pending decision" do
      it "gets status for the request issues" do
        issue_statuses = issues_hash(hlr.active_request_issues_or_decision_issues)
        expect(issue_statuses.count).to eq(2)

        issue = issue_statuses.find { |i| i[:diagnosticCode] == "9999" }
        expect(issue).to_not be_nil

        expect(issue[:active]).to eq(true)
        expect(issue[:lastAction]).to be_nil
        expect(issue[:date]).to be_nil
        expect(issue[:description]).to eq("Dental or oral condition")

        issue2 = issue_statuses.find { |i| i[:diagnosticCode] == "8877" }
        expect(issue2).to_not be_nil
        expect(issue2[:active]).to eq(true)
        expect(issue2[:lastAction]).to be_nil
        expect(issue2[:date]).to be_nil
        expect(issue2[:description]).to eq("Undiagnosed hemic or lymphatic condition")
      end

      context "with appeal_status_api_full_issue_description enabled" do
        before { FeatureToggle.enable!(:appeals_status_api_full_issue_description) }
        after { FeatureToggle.disable!(:appeals_status_api_full_issue_description) }

        it "gives the full request issue description" do
          issue_statuses = issues_hash(hlr.active_request_issues_or_decision_issues)

          issue = issue_statuses.find { |i| i[:diagnosticCode] == "9999" }
          expect(issue[:description]).to eq(request_issue1.contested_issue_description)

          issue2 = issue_statuses.find { |i| i[:diagnosticCode] == "8877" }
          expect(issue2[:description]).to eq(request_issue2.contested_issue_description)
        end
      end
    end

    context "decision on HLR, one decision has a DTA error" do
      let(:ep_status) { "CLR" }
      let!(:hlr_decision_issue_with_dta_error) do
        create(:decision_issue,
               decision_review: hlr,
               disposition: DecisionIssue::DTA_ERROR_PMR,
               benefit_type: benefit_type,
               end_product_last_action_date: receipt_date + 30.days,
               diagnostic_code: "9999")
      end

      let!(:hlr_decision_issue) do
        create(:decision_issue,
               decision_review: hlr,
               disposition: "denied",
               benefit_type: benefit_type,
               end_product_last_action_date: receipt_date + 30.days,
               diagnostic_code: "8877")
      end

      let!(:dta_sc) do
        create(:supplemental_claim,
               decision_review_remanded: hlr)
      end

      let(:dta_ep_status) { "PEND" }
      let!(:dta_ep) do
        create(:end_product_establishment,
               source: dta_sc,
               synced_status: dta_ep_status)
      end

      let!(:dta_request_issue) do
        create(:request_issue,
               decision_review: dta_sc,
               benefit_type: benefit_type,
               contested_rating_issue_diagnostic_code: "9999")
      end

      it "will still show the status for the request issues" do
        issue_statuses = issues_hash(hlr.active_request_issues_or_decision_issues)

        expect(issue_statuses.empty?).to eq(false)
        issue = issue_statuses.find { |i| i[:diagnosticCode] == "9999" }
        expect(issue).to_not be_nil
        expect(issue[:active]).to eq(true)
        expect(issue[:lastAction]).to be_nil
        expect(issue[:date]).to be_nil
        expect(issue[:description]).to eq("Dental or oral condition")

        issue2 = issue_statuses.find { |i| i[:diagnosticCode] == "8877" }
        expect(issue2).to_not be_nil
        expect(issue2[:active]).to eq(true)
        expect(issue2[:lastAction]).to be_nil
        expect(issue2[:date]).to be_nil
        expect(issue2[:description]).to eq("Undiagnosed hemic or lymphatic condition")
      end

      context "with appeal_status_api_full_issue_description enabled" do
        before { FeatureToggle.enable!(:appeals_status_api_full_issue_description) }
        after { FeatureToggle.disable!(:appeals_status_api_full_issue_description) }

        it "gives the full request issue description" do
          issue_statuses = issues_hash(hlr.active_request_issues_or_decision_issues)

          issue = issue_statuses.find { |i| i[:diagnosticCode] == "9999" }
          expect(issue[:description]).to eq(request_issue1.contested_issue_description)

          issue2 = issue_statuses.find { |i| i[:diagnosticCode] == "8877" }
          expect(issue2[:description]).to eq(request_issue2.contested_issue_description)
        end
      end
    end

    context "dta sc decision" do
      let(:ep_status) { "CLR" }

      let(:hlr_decision_date) { receipt_date + 30.days }
      let!(:hlr_decision_issue_with_dta_error) do
        create(:decision_issue,
               decision_review: hlr,
               disposition: DecisionIssue::DTA_ERROR_PMR,
               benefit_type: benefit_type,
               end_product_last_action_date: hlr_decision_date,
               diagnostic_code: "9999")
      end

      let!(:hlr_decision_issue) do
        create(:decision_issue,
               decision_review: hlr,
               description: "HLR decision issue description",
               disposition: "denied",
               benefit_type: benefit_type,
               end_product_last_action_date: hlr_decision_date,
               diagnostic_code: "8877")
      end

      let!(:dta_sc) do
        create(:supplemental_claim,
               decision_review_remanded: hlr)
      end

      let!(:dta_ep) do
        create(:end_product_establishment,
               source: dta_sc,
               synced_status: "CLR")
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
               description: "DTA SC decision issue description",
               disposition: "allowed",
               benefit_type: benefit_type,
               end_product_last_action_date: dta_sc_decision_date,
               diagnostic_code: "9999")
      end

      it "will get the status for the decisions issues" do
        issue_statuses = issues_hash(hlr.active_request_issues_or_decision_issues)

        expect(issue_statuses.empty?).to eq(false)
        issue = issue_statuses.find { |i| i[:diagnosticCode] == "9999" }
        expect(issue).to_not be_nil
        expect(issue[:active]).to eq(false)
        expect(issue[:lastAction]).to eq("allowed")
        expect(issue[:date]).to eq(dta_sc_decision_date.to_date)
        expect(issue[:description]).to eq("Dental or oral condition")

        issue2 = issue_statuses.find { |i| i[:diagnosticCode] == "8877" }
        expect(issue2).to_not be_nil
        expect(issue2[:active]).to eq(false)
        expect(issue2[:lastAction]).to eq("denied")
        expect(issue2[:date]).to eq(hlr_decision_date.to_date)
        expect(issue2[:description]).to eq("Undiagnosed hemic or lymphatic condition")
      end

      context "with appeal_status_api_full_issue_description enabled" do
        before { FeatureToggle.enable!(:appeals_status_api_full_issue_description) }
        after { FeatureToggle.disable!(:appeals_status_api_full_issue_description) }

        it "gives the full decision issue description" do
          issue_statuses = issues_hash(hlr.active_request_issues_or_decision_issues)

          issue = issue_statuses.find { |i| i[:diagnosticCode] == "9999" }
          expect(issue[:description]).to eq(dta_sc_decision_issue.description)

          issue2 = issue_statuses.find { |i| i[:diagnosticCode] == "8877" }
          expect(issue2[:description]).to eq(hlr_decision_issue.description)
        end
      end
    end
  end

  context "#supplemental_claim" do
    let(:receipt_date) { Time.new("2018", "03", "01").utc }
    let(:benefit_type) { "compensation" }

    let!(:sc) do
      create(:supplemental_claim,
             receipt_date: receipt_date,
             benefit_type: benefit_type)
    end

    let(:ep_status) { "PEND" }
    let!(:sc_ep) do
      create(:end_product_establishment,
             synced_status: ep_status, source: sc, last_synced_at: receipt_date + 100.days)
    end
    let!(:request_issue) do
      create(:request_issue,
             :nonrating,
             decision_review: sc,
             benefit_type: benefit_type,
             contested_rating_issue_diagnostic_code: nil)
    end

    context "claim is open, pending a decision" do
      it "status gives status info of the request issue" do
        issue_statuses = issues_hash(sc.active_request_issues_or_decision_issues)
        expect(issue_statuses.empty?).to eq(false)
        expect(issue_statuses.first[:active]).to eq(true)
        expect(issue_statuses.first[:lastAction]).to be_nil
        expect(issue_statuses.first[:date]).to be_nil
        expect(issue_statuses.first[:description]).to eq("Compensation issue")
        expect(issue_statuses.first[:diagnosticCode]).to be_nil
      end

      context "with appeal_status_api_full_issue_description enabled" do
        before { FeatureToggle.enable!(:appeals_status_api_full_issue_description) }
        after { FeatureToggle.disable!(:appeals_status_api_full_issue_description) }

        it "gives the full request issue description" do
          issue_statuses = issues_hash(sc.active_request_issues_or_decision_issues)

          issue = issue_statuses.first
          expect(issue[:description])
            .to eq("#{request_issue.nonrating_issue_category} - #{request_issue.nonrating_issue_description}")
        end
      end
    end

    context "claim has a decision" do
      let(:ep_status) { "CLR" }
      let!(:decision_issue) do
        create(:decision_issue,
               decision_review: sc, end_product_last_action_date: receipt_date + 100.days,
               benefit_type: benefit_type, diagnostic_code: nil)
      end

      it "status gives status info of the decision issue" do
        issue_statuses = issues_hash(sc.active_request_issues_or_decision_issues)
        expect(issue_statuses.empty?).to eq(false)
        expect(issue_statuses.first[:active]).to eq(false)
        expect(issue_statuses.first[:lastAction]).to eq("allowed")
        expect(issue_statuses.first[:date]).to eq((receipt_date + 100.days).to_date)
        expect(issue_statuses.first[:description]).to eq("Compensation issue")
        expect(issue_statuses.first[:diagnosticCode]).to be_nil
      end

      context "with appeal_status_api_full_issue_description enabled" do
        before { FeatureToggle.enable!(:appeals_status_api_full_issue_description) }
        after { FeatureToggle.disable!(:appeals_status_api_full_issue_description) }

        it "gives the full decision issue description" do
          issue_statuses = issues_hash(sc.active_request_issues_or_decision_issues)

          issue = issue_statuses.first
          expect(issue[:description]).to eq(decision_issue.description)
        end
      end
    end
  end
end
