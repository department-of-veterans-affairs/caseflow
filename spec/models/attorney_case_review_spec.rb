# frozen_string_literal: true

describe AttorneyCaseReview, :all_dbs do
  let(:attorney) { create(:user) }
  let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }

  let(:judge) { create(:user, station_id: User::BOARD_STATION_ID) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }

  context "#update_issue_dispositions_in_caseflow!" do
    let!(:appeal) { create(:appeal) }
    let(:task) { create(:ama_attorney_task, appeal: appeal) }
    let!(:request_issue1) { create(:request_issue, decision_review: appeal) }
    let(:decision_issue1) { build(:decision_issue) }
    let!(:request_issue2) { create(:request_issue, decision_review: appeal, decision_issues: [decision_issue1]) }

    let(:remand_reason1) { create(:ama_remand_reason) }
    let(:remand_reason2) { create(:ama_remand_reason) }
    let(:decision_issue2) do
      create(:decision_issue, remand_reasons: [remand_reason1, remand_reason2], decision_review: appeal)
    end
    let!(:request_issue3) { create(:request_issue, decision_review: appeal, decision_issues: [decision_issue2]) }
    let!(:request_issue4) { create(:request_issue, decision_review: appeal) }

    let!(:request_issue5) { create(:request_issue, decision_review: appeal) }

    let(:decision_issue3) { create(:decision_issue, decision_review: appeal) }
    let(:decision_issue4) { create(:decision_issue, decision_review: appeal) }
    let!(:request_issue6) do
      create(:request_issue, decision_review: appeal, decision_issues: [decision_issue3, decision_issue4])
    end
    let!(:withdrawn_request_issue) do
      create(
        :request_issue,
        decision_review: appeal,
        contested_issue_description: "Tinnitus",
        closed_at: Time.zone.now,
        closed_status: "withdrawn"
      )
    end

    subject { AttorneyCaseReview.new(issues: issues, task_id: task.id).update_issue_dispositions_in_caseflow! }

    context "when issue attributes are valid" do
      let(:issues) do
        [
          { disposition: "allowed", description: "something1",
            benefit_type: "compensation", diagnostic_code: "9999",
            request_issue_ids: [request_issue1.id, request_issue2.id] },
          { disposition: "remanded", description: "something2",
            benefit_type: "compensation", diagnostic_code: "9999",
            request_issue_ids: [request_issue1.id, request_issue2.id],
            remand_reasons: [
              { code: "va_records", post_aoj: false },
              { code: "incorrect_notice_sent", post_aoj: true },
              { code: "due_process_deficiency", post_aoj: false }
            ] },
          { disposition: "allowed", description: "something3",
            benefit_type: "compensation", diagnostic_code: "9999",
            request_issue_ids: [request_issue3.id, request_issue4.id] },
          { disposition: "allowed", description: "something4",
            benefit_type: "compensation", diagnostic_code: "9999",
            request_issue_ids: [request_issue5.id] },
          { disposition: "remanded", description: "something5",
            benefit_type: "compensation", diagnostic_code: "9999",
            request_issue_ids: [request_issue5.id],
            remand_reasons: [
              { code: "va_records", post_aoj: false },
              { code: "incorrect_notice_sent", post_aoj: true }
            ] },
          { disposition: "allowed", description: "something6",
            benefit_type: "compensation", diagnostic_code: "9999",
            request_issue_ids: [request_issue6.id] },
          { disposition: "withdrawn", description: "withdrawn decision issue",
            benefit_type: "compensation", diagnostic_code: "9999",
            request_issue_ids: [withdrawn_request_issue.id] }
        ]
      end

      it "should create and delete decision issues" do
        subject
        old_decision_issue_ids = [decision_issue1.id, decision_issue2.id, decision_issue3.id, decision_issue4.id]
        expect(DecisionIssue.where(id: old_decision_issue_ids)).to eq []
        expect(RequestDecisionIssue.where(decision_issue_id: old_decision_issue_ids)).to eq []

        # Ensure soft deleted records are there
        expect(DecisionIssue.unscoped.where(id: old_decision_issue_ids).size).to eq old_decision_issue_ids.size
        deleted_request_decision_issues = RequestDecisionIssue.unscoped.where(decision_issue_id: old_decision_issue_ids)
        expect(deleted_request_decision_issues.size).to eq old_decision_issue_ids.size

        expect(request_issue1.reload.decision_issues.size).to eq 2
        expect(request_issue2.reload.decision_issues.size).to eq 2
        expect(request_issue1.decision_issues).to eq request_issue2.decision_issues

        something1_decision = request_issue1.decision_issues.find { |di| di.description == "something1" }
        something2_decision = request_issue1.decision_issues.find { |di| di.description == "something2" }

        expect(something1_decision.disposition).to eq "allowed"
        expect(something2_decision.disposition).to eq "remanded"

        expect(something2_decision.remand_reasons.size).to eq 3
        expect(something2_decision.remand_reasons.find do |rr|
          rr.code == "va_records"
        end.post_aoj).to eq false
        expect(something2_decision.remand_reasons.find do |rr|
          rr.code == "incorrect_notice_sent"
        end.post_aoj).to eq true
        expect(something2_decision.remand_reasons.find do |rr|
          rr.code == "due_process_deficiency"
        end.post_aoj).to eq false

        expect(request_issue3.reload.decision_issues.size).to eq 1
        expect(request_issue4.reload.decision_issues.size).to eq 1
        expect(request_issue3.reload.decision_issues.first).to eq request_issue4.decision_issues.first
        expect(request_issue5.reload.decision_issues.size).to eq 2

        something5_decision = request_issue5.decision_issues.find { |di| di.description == "something5" }

        expect(something5_decision.remand_reasons.size).to eq 2

        expect(request_issue6.decision_issues.size).to eq 1
        expect(withdrawn_request_issue.decision_issues.size).to eq 1
        expect(withdrawn_request_issue.decision_issues[0].disposition).to eq "withdrawn"
      end
    end

    context "when missing remand reasons" do
      let(:issues) do
        [{ disposition: "allowed", description: "something1",
           benefit_type: "compensation", diagnostic_code: "9999",
           request_issue_ids: [request_issue1.id, request_issue2.id] },
         { disposition: "remanded", description: "something2",
           benefit_type: "compensation", diagnostic_code: "9999",
           request_issue_ids: [request_issue1.id, request_issue2.id] },
         { disposition: "allowed", description: "something3",
           benefit_type: "compensation", diagnostic_code: "9999",
           request_issue_ids: [request_issue3.id, request_issue4.id] },
         { disposition: "allowed", description: "something4",
           benefit_type: "compensation", diagnostic_code: "9999",
           request_issue_ids: [request_issue5.id] },
         { disposition: "remanded", description: "something5",
           benefit_type: "compensation", diagnostic_code: "9999",
           request_issue_ids: [request_issue5.id],
           remand_reasons: [
             { code: "va_records", post_aoj: false },
             { code: "incorrect_notice_sent", post_aoj: true }
           ] },
         { disposition: "allowed", description: "something6",
           benefit_type: "compensation", diagnostic_code: "9999",
           request_issue_ids: [request_issue6.id] }]
      end

      it "should raise AttorneyJudgeCheckoutError" do
        expect { subject }.to raise_error(Caseflow::Error::AttorneyJudgeCheckoutError)
        expect(AttorneyCaseReview.count).to eq 0
      end
    end

    context "when not all issues are sent" do
      let(:issues) do
        [{ disposition: "allowed", description: "something1",
           benefit_type: "compensation", diagnostic_code: "9999",
           request_issue_ids: [request_issue1.id, request_issue2.id] },
         { disposition: "remanded", description: "something2",
           benefit_type: "compensation", diagnostic_code: "9999",
           request_issue_ids: [request_issue1.id, request_issue2.id],
           remand_reasons: [
             { code: "va_records", post_aoj: false },
             { code: "incorrect_notice_sent", post_aoj: true }
           ] },
         { disposition: "allowed", description: "something3",
           benefit_type: "compensation", diagnostic_code: "9999",
           request_issue_ids: [request_issue3.id, request_issue4.id] },
         { disposition: "allowed", description: "something4",
           benefit_type: "compensation", diagnostic_code: "9999",
           request_issue_ids: [request_issue5.id] },
         { disposition: "remanded", description: "something5",
           benefit_type: "compensation", diagnostic_code: "9999",
           request_issue_ids: [request_issue5.id],
           remand_reasons: [
             { code: "va_records", post_aoj: false },
             { code: "incorrect_notice_sent", post_aoj: true }
           ] }]
      end

      it "should raise AttorneyJudgeCheckoutError" do
        expect { subject }.to raise_error(Caseflow::Error::AttorneyJudgeCheckoutError)
        expect(AttorneyCaseReview.count).to eq 0
      end
    end

    context "when no decision issues are sent and all request issues are closed" do
      let(:issues) { [] }

      it "should raise AttorneyJudgeCheckoutError" do
        appeal.reload.request_issues.each { |issue| issue.close!(status: :decided) }
        expect { subject }.to raise_error(Caseflow::Error::AttorneyJudgeCheckoutError)
        expect(AttorneyCaseReview.count).to eq 0
      end
    end
  end

  context ".complete" do
    let(:document_type) { Constants::APPEAL_DECISION_TYPES["OMO_REQUEST"] }
    let(:work_product) { "OMO - IME" }
    let(:document_id) { "M1234567.1234" }
    let(:padded_document_id) { "     #{document_id}    " }
    let(:note) { "something" }
    let(:task_id) { create(:ama_attorney_task, assigned_by: judge, assigned_to: attorney).id }
    let(:params) do
      {
        document_type: document_type,
        reviewing_judge: judge,
        work_product: work_product,
        document_id: padded_document_id,
        overtime: true,
        note: note,
        task_id: task_id,
        attorney: attorney
      }
    end

    before { User.authenticate!(user: attorney) }
    subject { AttorneyCaseReview.complete(params) }

    context "for omo request" do
      let(:task_id) { "#{vacols_case.bfkey}-#{vacols_case.decass[0].deadtim.strftime('%F')}" }
      let(:case_issues) { [] }
      let(:vacols_case) { create(:case, :assigned, staff: vacols_atty, case_issues: case_issues) }

      context "should validate format of the task ID" do
        context "when correct format" do
          it { is_expected.to be_valid }
        end

        context "when correct format with letters" do
          let(:case_id_w_trailing_letter) { "1989L" }
          let(:vacols_case) do
            create(:case, :assigned, staff: vacols_atty, bfkey: case_id_w_trailing_letter)
          end
          let(:task_id) { "#{vacols_case.bfkey}-#{vacols_case.decass[0].deadtim.strftime('%F')}" }
          it { is_expected.to be_valid }
        end

        context "when incorrect format" do
          let(:task_id) { "#{vacols_case.bfkey}-#{vacols_case.decass[0].deadtim.strftime('%D')}" }

          it { is_expected.to_not be_valid }
        end
      end

      context "when all parameters are present for omo request" do
        it "should create OMO Request record" do
          expect(subject.document_type).to eq Constants::APPEAL_DECISION_TYPES["OMO_REQUEST"]
          expect(subject.valid?).to eq true
          expect(subject.work_product).to eq work_product
          expect(subject.document_id).to eq document_id
          expect(subject.note).to eq note
          expect(subject.reviewing_judge).to eq judge
          expect(subject.attorney).to eq attorney

          expect(subject.appeal_type).to eq "LegacyAppeal"
          expect(subject.appeal_id).to eq LegacyAppeal.find_by_vacols_id(vacols_case.bfkey).id
        end
      end

      context "when not all required parameters are present" do
        let(:params) do
          {
            reviewing_judge: judge,
            work_product: work_product,
            document_id: document_id,
            overtime: true,
            note: note,
            task_id: task_id,
            attorney: attorney
          }
        end

        it "should not create AttorneyCaseReview record" do
          expect(subject.valid?).to eq false
          expect(subject.errors.full_messages.first).to eq "Document type can't be blank"
          expect(AttorneyCaseReview.count).to eq 0
        end
      end

      context "when Vacols update is not successful" do
        let(:date_in_past) { Time.zone.local(1989, 12, 13) }
        let(:task_id) { "#{vacols_case.bfkey}-#{date_in_past.strftime('%F')}" }

        it "should not create omo request record" do
          expect { subject }.to raise_error(Caseflow::Error::QueueRepositoryError)
          expect(AttorneyCaseReview.count).to eq 0
        end
      end
    end

    context "for draft decision" do
      let(:params) do
        {
          document_type: document_type,
          reviewing_judge: judge,
          work_product: work_product,
          document_id: padded_document_id,
          overtime: true,
          note: note,
          task_id: task_id,
          attorney: attorney,
          issues: issues
        }
      end

      context "when legacy" do
        let(:task_id) { "#{vacols_case.bfkey}-#{vacols_case.decass[0].deadtim.strftime('%F')}" }
        let(:vacols_case) { create(:case, :assigned, staff: vacols_atty, case_issues: case_issues) }
        let(:document_type) { Constants::APPEAL_DECISION_TYPES["DRAFT_DECISION"] }
        let(:work_product) { "Decision" }
        let(:document_id) { "12345-12345678" }
        let(:vacated_issue) { create(:case_issue, :disposition_vacated) }
        let(:remand_reason) { create(:remand_reason, rmdval: "AB", rmddev: "R2") }
        let(:remanded_issue) do
          create(:case_issue, :disposition_remanded, remand_reasons: [remand_reason])
        end
        let(:case_issues) { [vacated_issue, remanded_issue] }
        let(:issues) do
          [
            { disposition: case_issues[0].issdc,
              id: case_issues[0].issseq,
              readjudication: true },
            { disposition: case_issues[1].issdc,
              id: case_issues[1].issseq,
              remand_reasons: [{ code: remand_reason.rmdval, post_aoj: true }] }
          ]
        end

        context "when VACOLS update is successful" do
          let(:decass_record) do
            VACOLS::Decass.find_by(defolder: subject.vacols_id, deadtim: subject.created_in_vacols_date)
          end

          it "should create draft decision record" do
            expect(decass_record.deprod).to eq "OTD"
            expect(decass_record.deatcom).to eq note
            expect(decass_record.dedocid).to eq document_id
          end

          it "should update the location for the associated VACOLS::Case with the Judge's VACOLS ID" do
            expect(decass_record.case.bfcurloc).to eq judge.vacols_uniq_id
          end

          # TODO: We don't currently test that the most recent PRIORLOC record
          # (prior to this action) is updated with a LOCDIN date and LOCSTRCV
          # staffer because we aren't yet creating PRIORLOC records when we create BRIEFF records
          # through FactoryBot. Add a test to confirm we are correctly updating that PRIORLOC
          # record when we add this functionality to the BRIEFF factory.
          # Link to untested segment of code below:
          # https://github.com/department-of-veterans-affairs/caseflow/blob/5ddc24571b0aad8ba631d0d1169454343b4c4028/
          # app/models/vacols/case.rb#L236

          it "should create new priorloc record with attorney as staff who checked out case and judge as receiver" do
            judge_id = judge.vacols_uniq_id
            attorney_id = attorney.vacols_uniq_id
            expect(decass_record.case.priorloc.where(locstout: attorney_id, locstto: judge_id).count).to eq 1
          end
        end

        context "when Vacols update is not successful" do
          let(:issues) do
            [
              { disposition: case_issues[0].issdc,
                id: "1000",
                readjudication: true },
              { disposition: case_issues[1].issdc,
                id: case_issues[1].issseq,
                remand_reasons: [{ code: remand_reason.rmdval, post_aoj: true }] }
            ]
          end

          it "should not create draft decision record" do
            expect { subject }.to raise_error(Caseflow::Error::IssueRepositoryError)
            expect(AttorneyCaseReview.count).to eq 0
          end
        end

        context "when missing remand reasons" do
          let(:issues) do
            [
              { disposition: case_issues[0].issdc,
                id: case_issues[0].issseq,
                readjudication: true },
              { disposition: case_issues[1].issdc,
                id: case_issues[1].issseq }
            ]
          end

          it "should not create draft decision record" do
            expect { subject }.to raise_error(Caseflow::Error::RemandReasonRepositoryError)
            expect(AttorneyCaseReview.count).to eq 0
          end
        end

        context "when not all issues are sent" do
          let(:issues) do
            [
              { disposition: case_issues[1].issdc,
                id: case_issues[1].issseq,
                remand_reasons: [{ code: remand_reason.rmdval, post_aoj: true }] }
            ]
          end

          it "should not create draft decision record" do
            expect { subject }.to raise_error(Caseflow::Error::AttorneyJudgeCheckoutError)
            expect(AttorneyCaseReview.count).to eq 0
          end
        end

        context "when no issues are sent" do
          let(:issues) { nil }

          it "should not create draft decision record" do
            expect { subject }.to raise_error(Caseflow::Error::AttorneyJudgeCheckoutError)
            expect(AttorneyCaseReview.count).to eq 0
          end
        end
      end

      context "when ama" do
        let(:attorney_task) { Task.find(task_id) }
        let(:judge_task) { attorney_task.parent }
        let!(:request_issue1) do
          create(:request_issue,
                 decision_review: judge_task.appeal,
                 decision_issues: [build(:decision_issue)])
        end
        let(:request_issue2) do
          create(:request_issue,
                 decision_review: attorney_task.appeal,
                 decision_issues: [create(:decision_issue,
                                          remand_reasons: [create(:ama_remand_reason), create(:ama_remand_reason)],
                                          decision_review: attorney_task.appeal)])
        end
        let(:issues) do
          [{ disposition: "allowed", description: "something",
             benefit_type: "compensation", diagnostic_code: "9999",
             request_issue_ids: [request_issue1.id, request_issue2.id] },
           { disposition: "remanded", description: "somethingElse",
             benefit_type: "compensation", diagnostic_code: "9999",
             request_issue_ids: [request_issue1.id, request_issue2.id],
             remand_reasons: [
               { code: "va_records", post_aoj: false },
               { code: "incorrect_notice_sent", post_aoj: true },
               { code: "due_process_deficiency", post_aoj: false }
             ] }]
        end

        it "updates the assigned_by field to the attorney" do
          expect(judge_task.assigned_by).not_to eq(attorney)
          subject
          expect(judge_task.reload.assigned_by).to eq(attorney)
        end
        it "should create an AttorneyCaseReview record" do
          case_review = subject
          expect(case_review.appeal_type).to eq "Appeal"
          expect(case_review.appeal_id).to eq attorney_task.appeal.id

          expect(attorney_task.appeal.attorney_case_reviews).to include case_review
          expect(attorney_task.appeal.judge_case_reviews).to eq []
        end
        it "should check for erroneous AMA states"
      end
    end
  end
end
