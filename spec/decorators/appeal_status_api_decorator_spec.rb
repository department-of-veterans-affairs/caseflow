# frozen_string_literal: true

describe AppealStatusApiDecorator, :all_dbs do
  before do
    Timecop.freeze(pre_ama_start_date)
  end

  context "#program" do
    subject { described_class.new(appeal).program }

    let(:benefit_type1) { "compensation" }
    let(:benefit_type2) { "pension" }
    let(:appeal) { create(:appeal, request_issues: [request_issue]) }
    let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }
    let(:request_issue2) { create(:request_issue, benefit_type: benefit_type1) }
    let(:request_issue3) { create(:request_issue, benefit_type: benefit_type2) }

    context "appeal has one request issue" do
      it { is_expected.to eq benefit_type1 }
    end

    context "appeal has multiple request issues with same benefit type" do
      let(:appeal) { create(:appeal, request_issues: [request_issue, request_issue2]) }

      it { is_expected.to eq benefit_type1 }
    end

    context "appeal has multiple request issue with different benefit_types" do
      let(:appeal) { create(:appeal, request_issues: [request_issue, request_issue2, request_issue3]) }

      it { is_expected.to eq "multiple" }
    end
  end

  context "#active_status?" do
    subject { described_class.new(appeal).active_status? }

    context "there are in-progress tasks" do
      let(:appeal) { create(:appeal) }

      before do
        create_list(:task, 3, :in_progress, type: RootTask.name, appeal: appeal)
      end

      it "appeal is active" do
        expect(subject).to eq(true)
      end
    end

    context "has an effectuation ep that is active" do
      let(:appeal) { create(:appeal) }
      let(:decision_document) { create(:decision_document, appeal: appeal) }
      let(:ep_status) { "PEND" }
      let!(:effectuation_ep) { create(:end_product_establishment, source: decision_document, synced_status: ep_status) }

      it "appeal is active" do
        expect(subject).to eq(true)
      end

      context "effection ep cleared" do
        let(:ep_status) { "CLR" }

        it "appeal is not active" do
          expect(subject).to eq(false)
        end
      end
    end

    context "has an open remanded supplemental claim" do
      let(:appeal) { create(:appeal) }
      let(:remanded_sc) { create(:supplemental_claim, decision_review_remanded: appeal) }
      let(:ep_status) { "PEND" }
      let!(:remanded_ep) { create(:end_product_establishment, source: remanded_sc, synced_status: ep_status) }

      it "appeal is active" do
        expect(subject).to eq(true)
      end

      context "remanded supplemental_claim is closed" do
        let(:ep_status) { "CLR" }

        it "appeal is not active" do
          expect(subject).to eq(false)
        end
      end
    end
  end

  context "#location" do
    subject { described_class.new(appeal).location }

    context "has an active effectuation ep" do
      let(:appeal) { create(:appeal) }
      let(:decision_document) { create(:decision_document, appeal: appeal) }
      let(:ep_status) { "PEND" }
      let!(:effectuation_ep) { create(:end_product_establishment, source: decision_document, synced_status: ep_status) }

      it "is at aoj" do
        expect(subject).to eq("aoj")
      end

      context "effection ep cleared" do
        let(:ep_status) { "CLR" }

        it "is at bva" do
          expect(subject).to eq("bva")
        end
      end
    end

    context "has an open remanded supplemental claim" do
      let(:appeal) { create(:appeal) }
      let(:remanded_sc) { create(:supplemental_claim, decision_review_remanded: appeal) }
      let(:ep_status) { "PEND" }
      let!(:remanded_ep) { create(:end_product_establishment, source: remanded_sc, synced_status: ep_status) }

      it "is at aoj" do
        expect(subject).to eq("aoj")
      end

      context "remanded supplemental_claim is closed" do
        let(:ep_status) { "CLR" }

        it "is at bva" do
          expect(subject).to eq("bva")
        end
      end
    end
  end

  context "#events" do
    let(:receipt_date) { ama_test_start_date + 1 }
    let!(:appeal) { create(:appeal, receipt_date: receipt_date) }
    let!(:decision_date) { receipt_date + 130.days }
    let!(:decision_document) { create(:decision_document, appeal: appeal, decision_date: decision_date) }
    let(:judge) { create(:user) }
    let(:judge_task_created_date) { receipt_date + 10 }
    let!(:judge_review_task) do
      create(:ama_judge_decision_review_task, :completed,
             assigned_to: judge, appeal: appeal, created_at: judge_task_created_date)
    end
    let!(:judge_quality_review_task) do
      create(:ama_judge_quality_review_task, :completed,
             assigned_to: judge, appeal: appeal, created_at: judge_task_created_date + 2.days)
    end

    subject { described_class.new(appeal).events }

    context "decision, no remand and an effectuation" do
      let!(:decision_issue) { create(:decision_issue, decision_review: appeal, caseflow_decision_date: decision_date) }
      let(:ep_cleared_date) { receipt_date + 150.days }
      let!(:effectuation_ep) do
        create(:end_product_establishment,
               :cleared, source: decision_document, last_synced_at: ep_cleared_date)
      end

      it "has an nod event, judge assigned event, decision event and effectation event" do
        events = subject
        nod_event = events.find { |e| e.type == :ama_nod }
        expect(nod_event.date.to_date).to eq(receipt_date.to_date)

        judge_assigned_event = events.find { |e| e.type == :distributed_to_vlj }
        expect(judge_assigned_event.date.to_date).to eq(judge_task_created_date.to_date)

        decision_event = events.find { |e| e.type == :bva_decision }
        expect(decision_event.date.to_date).to eq(decision_date.to_date)

        effectuation_event = events.find { |e| e.type == :bva_decision_effectuation }
        expect(effectuation_event.date.to_date).to eq(ep_cleared_date.to_date)
      end
    end

    context "decision with a remand and an effectuation" do
      # the effectuation
      let!(:decision_issue) { create(:decision_issue, decision_review: appeal, caseflow_decision_date: decision_date) }
      let(:ep_cleared_date) { receipt_date + 150.days }
      let!(:effectuation_ep) do
        create(:end_product_establishment,
               :cleared, source: decision_document, last_synced_at: ep_cleared_date)
      end
      # the remand
      let!(:remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal, disposition: "remanded", benefit_type: "compensation")
      end
      let(:remanded_sc) { create(:supplemental_claim, decision_review_remanded: appeal) }
      let(:remanded_ep_clr_date) { receipt_date + 200.days }
      let!(:remanded_ep) { create(:end_product_establishment, :cleared, source: remanded_sc) }
      let!(:remanded_sc_decision_issue) do
        create(:decision_issue,
               decision_review: remanded_sc,
               end_product_last_action_date: remanded_ep_clr_date)
      end

      it "has nod event, judge assigned event, decision event, remand decision event" do
        events = subject
        nod_event = events.find { |e| e.type == :ama_nod }
        expect(nod_event.date.to_date).to eq(receipt_date.to_date)

        judge_assigned_event = events.find { |e| e.type == :distributed_to_vlj }
        expect(judge_assigned_event.date.to_date).to eq(judge_task_created_date.to_date)

        decision_event = events.find { |e| e.type == :bva_decision }
        expect(decision_event.date.to_date).to eq(decision_date.to_date)

        remand_decision_event = events.find { |e| e.type == :dta_decision }
        expect(remand_decision_event.date.to_date).to eq(remanded_ep_clr_date.to_date)

        effectuation_event = events.find { |e| e.type == :bva_decision_effectuation }
        expect(effectuation_event).to be_nil
      end
    end
  end

  context "#docket_hash" do
    let(:october_docket_date) { Time.new("2018", "10", "01").utc }
    let(:receipt_date) { october_docket_date + 20.days }

    let(:decision_date1) { receipt_date - 50.days }
    let(:request_issue1) { create(:request_issue, :nonrating, decision_date: decision_date1) }

    let(:decision_date2) { receipt_date - 60.days }
    let(:request_issue2) { create(:request_issue, :nonrating, decision_date: decision_date2) }

    let(:decision_date3) { receipt_date - 100.days }
    let(:removed_request_issue) do
      create(
        :request_issue,
        :nonrating,
        decision_date: decision_date3,
        closed_at: receipt_date
      )
    end

    let(:docket_type) { Constants.AMA_DOCKETS.direct_review }
    let!(:appeal) do
      create(:appeal,
             receipt_date: receipt_date,
             request_issues: [request_issue1, request_issue2, removed_request_issue],
             docket_type: docket_type)
    end

    let!(:root_task) { create(:root_task, :in_progress, appeal: appeal) }

    subject { described_class.new(appeal).docket_hash }

    context "all request issues have a decision or promulgation date" do
      it "is direct review, in Oct month, has docket switch deadline and is eligible to switch" do
        docket = subject

        expect(docket).not_to be_nil
        expect(docket[:type]).to eq("directReview")
        expect(docket[:month]).to eq(october_docket_date.to_date)
        expect(docket[:switchDueDate]).to eq((decision_date2 + 365.days).to_date)
        expect(docket[:eligibleToSwitch]).to eq(true)
      end
    end

    context "cannot get decision or promulgation date for an open request issue" do
      let(:decision_date1) { nil }
      let(:decision_date3) { nil }

      it "is direct review, in Oct month, has no switch deadline and is not eligible to switch" do
        docket = subject

        expect(docket).not_to be_nil
        expect(docket[:type]).to eq("directReview")
        expect(docket[:month]).to eq(october_docket_date.to_date)
        expect(docket[:switchDueDate]).to be_nil
        expect(docket[:eligibleToSwitch]).to eq(false)
      end
    end
  end

  context "#alerts" do
    subject { described_class.new(appeal).alerts }
    let(:receipt_date) { Time.zone.today - 10.days }
    let!(:appeal) { create(:appeal, :hearing_docket, receipt_date: receipt_date) }

    context "has a remand and effectuation tracked in VBMS" do
      # the effectuation
      let(:decision_date) { receipt_date + 30.days }
      let!(:decision_document) { create(:decision_document, appeal: appeal, decision_date: decision_date) }
      let!(:decision_issue) do
        create(:decision_issue,
               decision_review: appeal, disposition: "allowed", caseflow_decision_date: decision_date)
      end
      let(:effectuation_ep_cleared_date) { receipt_date + 250.days }
      let!(:effectuation_ep) do
        create(:end_product_establishment,
               :cleared, source: decision_document, last_synced_at: effectuation_ep_cleared_date)
      end
      # the remand
      let!(:remanded_decision_issue) do
        create(:decision_issue,
               decision_review: appeal,
               disposition: "remanded",
               benefit_type: "compensation",
               caseflow_decision_date: decision_date)
      end
      let!(:remanded_sc) { create(:supplemental_claim, decision_review_remanded: appeal) }
      let(:remanded_ep_clr_date) { receipt_date + 200.days }
      let!(:remanded_ep) { create(:end_product_establishment, :cleared, source: remanded_sc) }
      let!(:remanded_sc_decision_issue) do
        create(:decision_issue,
               decision_review: remanded_sc,
               end_product_last_action_date: remanded_ep_clr_date)
      end

      it "has 3 ama_post_decision alerts" do
        expect(subject.count).to eq(3)

        expect(subject[0][:type]).to eq("ama_post_decision")
        expect(subject[0][:details][:availableOptions]).to eq(%w[supplemental_claim cavc])
        expect(subject[0][:details][:dueDate].to_date).to eq((decision_date + 365.days).to_date)
        expect(subject[0][:details][:cavcDueDate].to_date).to eq((decision_date + 120.days).to_date)

        expect(subject[1][:type]).to eq("ama_post_decision")
        expect(subject[1][:details][:availableOptions]).to eq(%w[supplemental_claim higher_level_review appeal])
        expect(subject[1][:details][:dueDate].to_date).to eq((remanded_ep_clr_date + 365.days).to_date)
        expect(subject[1][:details][:cavcDueDate].to_date).to eq((remanded_ep_clr_date + 120.days).to_date)

        expect(subject[2][:type]).to eq("ama_post_decision")
        expect(subject[2][:details][:availableOptions]).to eq(%w[supplemental_claim cavc])
        expect(subject[2][:details][:dueDate].to_date).to eq((effectuation_ep_cleared_date + 365.days).to_date)
        expect(subject[2][:details][:cavcDueDate].to_date).to eq((effectuation_ep_cleared_date + 120.days).to_date)
      end
    end

    context "has an open evidence submission task" do
      let!(:evidence_submission_task) do
        create(:evidence_submission_window_task, :in_progress, appeal: appeal, assigned_to: Bva.singleton)
      end

      before do
        appeal.update(docket_type: Constants.AMA_DOCKETS.evidence_submission)
      end

      it "has an evidentiary_period alert" do
        expect(subject.count).to eq(1)
        expect(subject[0][:type]).to eq("evidentiary_period")
        expect(subject[0][:details][:due_date]).to eq((receipt_date + 90.days).to_date)
      end
    end

    context "has a scheduled hearing" do
      let!(:appeal_root_task) { create(:root_task, :in_progress, appeal: appeal) }
      let!(:hearing_task) { create(:hearing_task, parent: appeal_root_task) }
      let(:hearing_scheduled_for) { Time.zone.today + 15.days }
      let!(:hearing_day) do
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               regional_office: "RO18",
               scheduled_for: hearing_scheduled_for)
      end

      let!(:hearing) do
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

      it "has a scheduled hearing alert" do
        expect(subject.count).to eq(1)
        expect(subject[0][:type]).to eq("scheduled_hearing")
        expect(subject[0][:details][:date]).to eq(hearing_scheduled_for.to_date)
        expect(subject[0][:details][:type]).to eq("video")
      end
    end
  end

  context "#scheduled_hearing" do
    subject { described_class.new(appeal).scheduled_hearing }
    let(:receipt_date) { Time.zone.today - 10.days }
    let!(:appeal) { create(:appeal, :hearing_docket, receipt_date: receipt_date) }

    let(:hearing_scheduled_for) { Time.zone.today + 15.days }
    let!(:hearing_day) do
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             regional_office: "RO18",
             scheduled_for: hearing_scheduled_for)
    end

    let!(:hearing) do
      create(
        :hearing,
        appeal: appeal,
        disposition: disposition,
        evidence_window_waived: nil,
        hearing_day: hearing_day
      )
    end

    context "when a hearing scheduled for the future has not been held" do
      let(:disposition) { nil }

      it "returns that hearing" do
        expect(subject).to eq(hearing)
      end
    end

    context "when a hearing scheduled for the future has been cancelled" do
      let(:disposition) { "cancelled" }

      it "returns no hearing" do
        expect(subject).to be_nil
      end
    end
  end
end
