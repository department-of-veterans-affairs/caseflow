describe HigherLevelReview do
  before do
    FeatureToggle.enable!(:intake_legacy_opt_in)
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:intake_legacy_opt_in)
  end

  let(:veteran_file_number) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: veteran_file_number) }
  let(:receipt_date) { DecisionReview.ama_activation_date + 1 }
  let(:benefit_type) { "compensation" }
  let(:informal_conference) { nil }
  let(:same_office) { nil }
  let(:legacy_opt_in_approved) { false }
  let(:veteran_is_not_claimant) { false }
  let(:profile_date) { receipt_date - 1 }
  let(:promulgation_date) { receipt_date - 1 }
  let(:caseflow_decision_date) { nil }

  let(:higher_level_review) do
    HigherLevelReview.new(
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      informal_conference: informal_conference,
      same_office: same_office,
      benefit_type: benefit_type,
      legacy_opt_in_approved: legacy_opt_in_approved,
      veteran_is_not_claimant: veteran_is_not_claimant
    )
  end

  context "#valid?" do
    subject { higher_level_review.valid? }

    context "receipt_date" do
      context "when it is nil" do
        let(:receipt_date) { nil }
        it { is_expected.to be true }
      end

      context "when it is after today" do
        let(:receipt_date) { 1.day.from_now }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(higher_level_review.errors[:receipt_date]).to include("in_future")
        end
      end

      context "when it is before AMA begin date" do
        let(:receipt_date) { DecisionReview.ama_activation_date - 1 }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(higher_level_review.errors[:receipt_date]).to include("before_ama")
        end
      end

      context "when saving receipt" do
        before { higher_level_review.start_review! }

        context "when it is nil" do
          let(:receipt_date) { nil }

          it "adds error to receipt_date" do
            is_expected.to be false
            expect(higher_level_review.errors[:receipt_date]).to include("blank")
          end
        end
      end
    end

    context "informal_conference, same_office, legacy opt-in, veteran_is_not_claimant" do
      context "when saving review" do
        before { higher_level_review.start_review! }

        context "when they are set" do
          let(:informal_conference) { true }
          let(:same_office) { false }
          let(:legacy_opt_in_approved) { false }

          it "is valid" do
            is_expected.to be true
          end
        end

        context "when they are nil" do
          let(:legacy_opt_in_approved) { nil }
          let(:veteran_is_not_claimant) { nil }
          it "adds errors to informal_conference and same_office" do
            is_expected.to be false
            expect(higher_level_review.errors[:informal_conference]).to include("blank")
            expect(higher_level_review.errors[:same_office]).to include("blank")
            expect(higher_level_review.errors[:legacy_opt_in_approved]).to include("blank")
            expect(higher_level_review.errors[:veteran_is_not_claimant]).to include("blank")
          end
        end
      end
    end
  end

  context "#claimant_participant_id" do
    subject { higher_level_review.claimant_participant_id }

    it "returns claimant's participant ID" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "00")
      higher_level_review.save!
      expect(subject).to eql("12345")
    end

    it "returns new claimant's participant ID if replaced" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "00")
      higher_level_review.create_claimants!(participant_id: "23456", payee_code: "00")
      higher_level_review.reload
      expect(subject).to eql("23456")
    end

    it "returns nil when there are no claimants" do
      expect(subject).to be_nil
    end
  end

  context "#payee_code" do
    subject { higher_level_review.payee_code }

    it "returns claimant's payee_code" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "10")
      higher_level_review.save!
      expect(subject).to eql("10")
    end

    it "returns new claimant's payee_code if replaced" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "10")
      higher_level_review.create_claimants!(participant_id: "23456", payee_code: "11")
      higher_level_review.reload
      expect(subject).to eql("11")
    end

    it "returns nil when there are no claimants" do
      expect(subject).to be_nil
    end
  end

  context "#claimant_not_veteran" do
    subject { higher_level_review.claimant_not_veteran }

    it "returns true if claimant is not veteran" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: "12345", payee_code: "10")
      expect(subject).to be true
    end

    it "returns false if claimant is veteran" do
      higher_level_review.save!
      higher_level_review.create_claimants!(participant_id: veteran.participant_id, payee_code: "00")
      expect(subject).to be false
    end

    it "returns nil if there are no claimants" do
      expect(subject).to be_nil
    end
  end

  context "#on_decision_issues_sync_processed" do
    subject { higher_level_review.on_decision_issues_sync_processed(end_product_establishment) }

    let(:end_product_establishment) do
      create(:end_product_establishment,
             source: higher_level_review)
    end

    context "when there are dta errors" do
      let!(:decision_issues) do
        [
          create(:decision_issue,
                 decision_review: higher_level_review,
                 disposition: DecisionIssue::DTA_ERROR_PMR,
                 rating_issue_reference_id: "rating1",
                 profile_date: profile_date,
                 promulgation_date: promulgation_date,
                 caseflow_decision_date: caseflow_decision_date,
                 benefit_type: benefit_type),
          create(:decision_issue,
                 decision_review: higher_level_review,
                 disposition: DecisionIssue::DTA_ERROR_FED_RECS,
                 rating_issue_reference_id: "rating2",
                 profile_date: profile_date,
                 promulgation_date: promulgation_date,
                 caseflow_decision_date: caseflow_decision_date,
                 benefit_type: benefit_type),
          create(:decision_issue,
                 decision_review: higher_level_review,
                 caseflow_decision_date: caseflow_decision_date,
                 benefit_type: benefit_type,
                 disposition: "not a dta error")
        ]
      end

      let!(:claimant) do
        Claimant.create!(
          review_request: higher_level_review,
          participant_id: veteran.participant_id,
          payee_code: "10"
        )
      end

      context "when there is no approx_decision_date" do
        let(:benefit_type) { "education" }
        let(:caseflow_decision_date) { nil }

        it "throws an error" do
          expect { subject }.to raise_error(
            StandardError, "approx_decision_date is required to create a DTA Supplemental Claim"
          )
        end
      end

      it "creates a supplemental claim and request issues" do
        expect { subject }.to_not change(DecisionReviewTask, :count)

        supplemental_claim = SupplementalClaim.find_by(
          decision_review_remanded: higher_level_review,
          veteran_file_number: higher_level_review.veteran_file_number,
          receipt_date: decision_issues.first.approx_decision_date,
          benefit_type: higher_level_review.benefit_type,
          legacy_opt_in_approved: higher_level_review.legacy_opt_in_approved,
          veteran_is_not_claimant: higher_level_review.veteran_is_not_claimant
        )

        expect(supplemental_claim).to_not be_nil
        expect(supplemental_claim.establishment_submitted_at).to_not be_nil
        expect(supplemental_claim.request_issues.count).to eq(2)

        first_dta_request_issue = RequestIssue.find_by(
          decision_review: supplemental_claim,
          contested_decision_issue_id: decision_issues.first.id,
          contested_rating_issue_reference_id: "rating1",
          contested_rating_issue_profile_date: decision_issues.first.profile_date.to_s,
          contested_issue_description: decision_issues.first.description,
          issue_category: decision_issues.first.issue_category,
          benefit_type: higher_level_review.benefit_type,
          decision_date: decision_issues.first.approx_decision_date
        )

        expect(first_dta_request_issue).to_not be_nil
        expect(first_dta_request_issue.end_product_establishment.code).to eq("040HDER")

        second_dta_request_issue = RequestIssue.find_by(
          decision_review: supplemental_claim,
          contested_decision_issue_id: decision_issues.second.id,
          contested_rating_issue_reference_id: "rating2",
          contested_rating_issue_profile_date: decision_issues.second.profile_date.to_s,
          contested_issue_description: decision_issues.first.description,
          issue_category: decision_issues.second.issue_category,
          benefit_type: higher_level_review.benefit_type,
          decision_date: decision_issues.second.approx_decision_date
        )

        expect(second_dta_request_issue).to_not be_nil
        expect(second_dta_request_issue.end_product_establishment.code).to eq("040HDER")
      end

      context "when benefit type is pension" do
        let(:benefit_type) { "pension" }

        it "creates end product establishment with pension ep code" do
          expect { subject }.to_not change(DecisionReviewTask, :count)

          first_dta_request_issue = RequestIssue.find_by(contested_rating_issue_reference_id: "rating1")

          expect(first_dta_request_issue.end_product_establishment.code).to eq("040HDERPMC")
        end
      end

      context "when benefit type is processed in caseflow" do
        let(:benefit_type) { "voc_rehab" }
        let(:caseflow_decision_date) { profile_date }

        it "creates DecisionReviewTask" do
          expect { subject }.to change(DecisionReviewTask, :count).by(1)
        end
      end
    end

    context "when there are no dta errors" do
      it "does nothing" do
        subject

        expect(SupplementalClaim.where.not(decision_review_remanded: nil).empty?).to eq(true)
        expect(RequestIssue.all.empty?).to eq(true)
      end
    end
  end

  context "#events" do
    let(:veteran_file_number) { "123456789" }
    let(:promulgation_date) { receipt_date + 130.days }

    context "hlr has a decision with no dta error" do
      let(:hlr) do
        create(:higher_level_review,
               veteran_file_number: veteran_file_number,
               receipt_date: receipt_date)
      end

      let!(:decision_issue) do
        create(:decision_issue,
               decision_review: hlr,
               disposition: "not a dta error",
               profile_date: promulgation_date,
               promulgation_date: promulgation_date)
      end

      it "has a request event and a decision event" do
        events = hlr.events
        request_event = events.find { |e| e.type == :hlr_request }
        expect(request_event.date.to_date).to eq(receipt_date.to_date)

        decision_event = events.find { |e| e.type == :hlr_decision }
        expect(decision_event.date.to_date).to eq(promulgation_date.to_date)
      end
    end

    context "hlr closed with no decision" do
      let(:hlr) do
        create(:higher_level_review,
               veteran_file_number: veteran_file_number,
               receipt_date: receipt_date)
      end

      let(:last_synced_at) { receipt_date + 20.days }
      let!(:hlr_ep) do
        create(:end_product_establishment,
               :cleared,
               source: hlr,
               last_synced_at: last_synced_at)
      end

      it "has a request and closed event" do
        events = hlr.events
        request_event = events.find { |e| e.type == :hlr_request }
        expect(request_event.date.to_date).to eq(receipt_date.to_date)

        closed_event = events.find { |e| e.type == :hlr_other_close }
        expect(closed_event.date.to_date).to eq(last_synced_at.to_date)
      end
    end

    context "hlr has dta error and remanded sc decision" do
      let(:hlr_ep_clr_date) { receipt_date + 30 }
      let!(:hlr_with_dta_error) do
        create(:higher_level_review,
               veteran_file_number: veteran_file_number,
               receipt_date: receipt_date)
      end

      let!(:hlr_end_product) do
        create(:end_product_establishment, :cleared, source: hlr_with_dta_error)
      end

      let!(:hlr_decision_issue_with_dta_error) do
        create(:decision_issue,
               decision_review: hlr_with_dta_error,
               disposition: DecisionIssue::DTA_ERROR_PMR,
               rating_issue_reference_id: "rating1",
               benefit_type: benefit_type,
               end_product_last_action_date: hlr_ep_clr_date)
      end

      let!(:dta_sc) do
        create(:supplemental_claim,
               veteran_file_number: veteran_file_number,
               decision_review_remanded: hlr_with_dta_error)
      end

      let(:promulgation_date) { receipt_date + 130.days }
      let!(:dta_ep) do
        create(:end_product_establishment, :cleared, source: dta_sc)
      end

      let!(:remanded_sc_decision_issue) do
        create(:decision_issue,
               decision_review: dta_sc,
               end_product_last_action_date: promulgation_date)
      end

      it "has a request event, hlr_dta_error event and dta_decision event" do
        events = hlr_with_dta_error.events
        request_event = events.find { |e| e.type == :hlr_request }
        expect(request_event.date.to_date).to eq(receipt_date.to_date)

        hlr_dta_error_event = events.find { |e| e.type == :hlr_dta_error }
        expect(hlr_dta_error_event.date.to_date).to eq(hlr_ep_clr_date.to_date)

        dta_decision_event = events.find { |e| e.type == :dta_decision }
        expect(dta_decision_event.date.to_date).to eq(promulgation_date.to_date)
      end
    end
  end

  context "#issues" do
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
             contested_rating_issue_diagnostic_code: "9999")
    end

    let!(:request_issue2) do
      create(:request_issue,
             decision_review: hlr,
             benefit_type: benefit_type,
             contested_rating_issue_diagnostic_code: "8877")
    end

    let!(:hlr) do
      create(:higher_level_review,
             veteran_file_number: veteran_file_number,
             receipt_date: receipt_date,
             benefit_type: benefit_type)
    end

    context "claim open pending decision" do
      it "gets status for the request issues" do
        issue_statuses = hlr.issues_hash

        expect(issue_statuses.empty?).to eq(false)

        issue = issue_statuses.find { |i| i[:diagnosticCode] == "9999" }
        expect(issue).to_not be_nil
        expect(issue[:active]).to eq(true)
        expect(issue[:last_action]).to be_nil
        expect(issue[:date]).to be_nil
        expect(issue[:description]).to eq("Dental or oral condition")

        issue2 = issue_statuses.find { |i| i[:diagnosticCode] == "8877" }
        expect(issue2).to_not be_nil
        expect(issue2[:active]).to eq(true)
        expect(issue2[:last_action]).to be_nil
        expect(issue2[:date]).to be_nil
        expect(issue2[:description]).to eq("Undiagnosed hemic or lymphatic condition")
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
               veteran_file_number: veteran_file_number,
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
        issue_statuses = hlr.issues_hash

        expect(issue_statuses.empty?).to eq(false)

        issue = issue_statuses.find { |i| i[:diagnosticCode] == "9999" }
        expect(issue).to_not be_nil
        expect(issue[:active]).to eq(true)
        expect(issue[:last_action]).to be_nil
        expect(issue[:date]).to be_nil
        expect(issue[:description]).to eq("Dental or oral condition")

        issue2 = issue_statuses.find { |i| i[:diagnosticCode] == "8877" }
        expect(issue2).to_not be_nil
        expect(issue2[:active]).to eq(true)
        expect(issue[:last_action]).to be_nil
        expect(issue[:date]).to be_nil
        expect(issue2[:description]).to eq("Undiagnosed hemic or lymphatic condition")
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
               disposition: "denied",
               benefit_type: benefit_type,
               end_product_last_action_date: hlr_decision_date,
               diagnostic_code: "8877")
      end

      let!(:dta_sc) do
        create(:supplemental_claim,
               veteran_file_number: veteran_file_number,
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
               disposition: "allowed",
               benefit_type: benefit_type,
               end_product_last_action_date: dta_sc_decision_date,
               diagnostic_code: "9999")
      end

      it "will get the status for the decisions issues" do
        issue_statuses = hlr.issues_hash
        expect(issue_statuses.empty?).to eq(false)

        issue = issue_statuses.find { |i| i[:diagnosticCode] == "9999" }
        expect(issue).to_not be_nil
        expect(issue[:active]).to eq(false)
        expect(issue[:last_action]).to eq("allowed")
        expect(issue[:date]).to eq(dta_sc_decision_date.to_date)
        expect(issue[:description]).to eq("Dental or oral condition")

        issue2 = issue_statuses.find { |i| i[:diagnosticCode] == "8877" }
        expect(issue2).to_not be_nil
        expect(issue2[:active]).to eq(false)
        expect(issue2[:last_action]).to eq("denied")
        expect(issue2[:date]).to eq(hlr_decision_date.to_date)
        expect(issue2[:description]).to eq("Undiagnosed hemic or lymphatic condition")
      end
    end
  end

  context "#status_hash" do
    let(:receipt_date) { Time.new("2018", "03", "01").utc }
    let(:benefit_type) { "compensation" }
    let(:hlr_decision_date) { receipt_date + 30.days }

    let!(:hlr) do
      create(:higher_level_review,
             veteran_file_number: veteran_file_number,
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
        status = hlr.status_hash
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
               veteran_file_number: veteran_file_number,
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
               veteran_file_number: veteran_file_number,
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
        status = hlr.status_hash

        expect(status[:type]).to eq(:hlr_decision)
        expect(status[:details][:issues].first[:description]).to eq("Dental or oral condition")
        expect(status[:details][:issues].first[:disposition]).to eq("allowed")
      end
    end
  end
end
