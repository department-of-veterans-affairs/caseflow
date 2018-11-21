describe AttorneyCaseReview do
  let(:attorney) { FactoryBot.create(:user) }
  let(:judge) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID) }

  context "#create_and_delete_decision_issues" do
    let(:appeal) { create(:appeal) }
    let(:task) { create(:ama_attorney_task, appeal: appeal) }
    let(:request_issue1) { create(:request_issue, review_request: appeal) }
    let(:decision_issue1) { create(:decision_issue) }
    let(:request_issue2) { create(:request_issue, review_request: appeal, decision_issues: [decision_issue1]) }

    let(:decision_issue2) { create(:decision_issue) }
    let(:request_issue3) { create(:request_issue, review_request: appeal, decision_issues: [decision_issue2]) }
    let(:request_issue4) { create(:request_issue, review_request: appeal) }

    let(:request_issue5) { create(:request_issue, review_request: appeal) }

    let(:decision_issue3) { create(:decision_issue) }
    let(:decision_issue4) { create(:decision_issue) }
    let(:request_issue6) do
      create(:request_issue, review_request: appeal, decision_issues: [decision_issue3, decision_issue4])
    end

    let(:issues) do
      [{ disposition: "allowed", description: "something1",
         request_issue_ids: [request_issue1.id, request_issue2.id] },
       { disposition: "remanded", description: "something2",
         request_issue_ids: [request_issue1.id, request_issue2.id] },
       { disposition: "allowed", description: "something3",
         request_issue_ids: [request_issue3.id, request_issue4.id] },
       { disposition: "allowed", description: "something4",
         request_issue_ids: [request_issue5.id] },
       { disposition: "remanded", description: "something5",
         request_issue_ids: [request_issue5.id] },
       { disposition: "allowed", description: "something6",
         request_issue_ids: [request_issue6.id] }]
    end

    subject { AttorneyCaseReview.new(issues: issues, task_id: task.id).delete_and_create_decision_issues }

    it "should create and delete decision issues" do
      subject
      old_decision_issue_ids = [decision_issue1.id, decision_issue2.id, decision_issue3.id, decision_issue4.id]
      expect(DecisionIssue.where(id: old_decision_issue_ids)).to eq []
      expect(RequestDecisionIssue.where(decision_issue_id: old_decision_issue_ids)).to eq []
      expect(request_issue1.reload.decision_issues.size).to eq 2
      expect(request_issue2.reload.decision_issues.size).to eq 2
      expect(request_issue1.decision_issues).to eq request_issue2.decision_issues
      expect(request_issue3.reload.decision_issues.size).to eq 1
      expect(request_issue4.reload.decision_issues.size).to eq 1
      expect(request_issue3.reload.decision_issues.first).to eq request_issue4.decision_issues.first
      expect(request_issue5.reload.decision_issues.size).to eq 2
      expect(request_issue6.decision_issues.size).to eq 1
    end
  end

  context ".complete" do
    let(:document_type) { Constants::APPEAL_DECISION_TYPES["OMO_REQUEST"] }
    let(:work_product) { "OMO - IME" }
    let(:document_id) { "123456789.1234" }
    let(:note) { "something" }
    let(:params) do
      {
        document_type: document_type,
        reviewing_judge: judge,
        work_product: work_product,
        document_id: document_id,
        overtime: true,
        note: note,
        task_id: task_id,
        attorney: attorney
      }
    end

    before { User.authenticate!(user: attorney) }
    subject { AttorneyCaseReview.complete(params) }

    context "when ama" do
      let(:task_id) { create(:ama_attorney_task).id }

      context "when all parameters are present" do
        it "should create draft decision record" do
          expect(subject.document_type).to eq Constants::APPEAL_DECISION_TYPES["OMO_REQUEST"]
          expect(subject.valid?).to eq true
          expect(subject.work_product).to eq work_product
          expect(subject.document_id).to eq document_id
          expect(subject.note).to eq note
          expect(subject.reviewing_judge).to eq judge
          expect(subject.attorney).to eq attorney
        end
      end
    end

    context "when legacy" do
      let(:task_id) { "#{vacols_case.bfkey}-#{vacols_case.decass[0].deadtim.strftime('%F')}" }
      let!(:vacols_atty) { FactoryBot.create(:staff, :attorney_role, sdomainid: attorney.css_id) }
      let!(:vacols_judge) { FactoryBot.create(:staff, :judge_role, sdomainid: judge.css_id) }
      let(:case_issues) { [] }
      let(:vacols_case) { FactoryBot.create(:case, :assigned, staff: vacols_atty, case_issues: case_issues) }

      context "should validate format of the task ID" do
        context "when correct format" do
          it { is_expected.to be_valid }
        end

        context "when correct format with letters" do
          let(:case_id_w_trailing_letter) { "1989L" }
          let(:vacols_case) do
            FactoryBot.create(:case, :assigned, staff: vacols_atty, bfkey: case_id_w_trailing_letter)
          end
          let(:task_id) { "#{vacols_case.bfkey}-#{vacols_case.decass[0].deadtim.strftime('%F')}" }
          it { is_expected.to be_valid }
        end

        context "when incorrect format" do
          let(:task_id) { "#{vacols_case.bfkey}-#{vacols_case.decass[0].deadtim.strftime('%D')}" }

          it { is_expected.to_not be_valid }
        end
      end

      context "when all parameters are present for OMO Request and Vacols update is successful" do
        it "should create OMO Request record" do
          expect(subject.document_type).to eq Constants::APPEAL_DECISION_TYPES["OMO_REQUEST"]
          expect(subject.valid?).to eq true
          expect(subject.work_product).to eq work_product
          expect(subject.document_id).to eq document_id
          expect(subject.note).to eq note
          expect(subject.reviewing_judge).to eq judge
          expect(subject.attorney).to eq attorney
        end
      end

      context "when not all required parameters are present and VACOLS update is successful" do
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

      context "when all parameters are present for OMO Request but Vacols update is not successful" do
        let(:date_in_past) { Time.zone.local(1989, 12, 13) }
        let(:task_id) { "#{vacols_case.bfkey}-#{date_in_past.strftime('%F')}" }

        it "should not create OMORequest record" do
          expect { subject }.to raise_error(Caseflow::Error::QueueRepositoryError)
          expect(AttorneyCaseReview.count).to eq 0
        end
      end

      context "draft decision" do
        let(:params) do
          {
            document_type: document_type,
            reviewing_judge: judge,
            work_product: work_product,
            document_id: document_id,
            overtime: true,
            note: note,
            task_id: task_id,
            attorney: attorney,
            issues: issues
          }
        end

        context "when ama" do
          let(:document_type) { Constants::APPEAL_DECISION_TYPES["DRAFT_DECISION"] }
          let(:work_product) { "Decision" }
          let(:task) { create(:ama_attorney_task) }
          let(:task_id) { task.id }
          let(:request_issue1) do
            create(:request_issue, review_request: task.appeal, disposition: "remanded")
          end
          # should delete this remand reason since disposition will be changed to 'allowed'
          let!(:remand_reason1) { create(:ama_remand_reason, request_issue: request_issue1) }

          let(:request_issue2) { create(:request_issue, review_request: task.appeal) }

          # For this issue, ensure we delete remand reasons that are not passed in the request
          let(:request_issue3) do
            create(:request_issue, review_request: task.appeal, disposition: "remanded")
          end
          let!(:remand_reasons) do
            [
              create(:ama_remand_reason, request_issue: request_issue3, code: "incorrect_notice_sent"),
              create(:ama_remand_reason, request_issue: request_issue3, code: "va_records"),
              create(:ama_remand_reason, request_issue: request_issue3, code: "other_government_records")
            ]
          end

          let(:issues) do
            [
              { "disposition" => "allowed",
                "id" => request_issue1.id },
              { "disposition" => "remanded",
                "id" => request_issue2.id,
                "remand_reasons" => [{ "code" => "incorrect_notice_sent", "post_aoj" => true }] },
              { "disposition" => "remanded",
                "id" => request_issue3.id,
                "remand_reasons" => [
                  { "code" => "incorrect_notice_sent", "post_aoj" => false },
                  { "code" => "medical_opinions", "post_aoj" => false }
                ] }
            ]
          end

          it "should create a draft decision, update issues and remand_reasons" do
            expect(request_issue1.remand_reasons.size).to eq 1
            expect(request_issue3.remand_reasons.size).to eq 3
            expect(subject.document_type).to eq Constants::APPEAL_DECISION_TYPES["DRAFT_DECISION"]
            expect(subject.valid?).to eq true
            expect(subject.work_product).to eq "Decision"
            expect(subject.document_id).to eq document_id
            expect(subject.note).to eq note
            expect(subject.reviewing_judge).to eq judge
            expect(subject.attorney).to eq attorney
            expect(request_issue1.reload.disposition).to eq "allowed"
            expect(request_issue1.remand_reasons.size).to eq 0
            expect(request_issue2.reload.disposition).to eq "remanded"
            expect(request_issue2.remand_reasons.size).to eq 1
            expect(request_issue3.reload.remand_reasons.size).to eq 2
            expect(request_issue3.remand_reasons.first.code).to eq "incorrect_notice_sent"
            expect(request_issue3.remand_reasons.first.post_aoj).to eq false
            expect(request_issue3.remand_reasons.second.code).to eq "medical_opinions"
            expect(request_issue3.remand_reasons.second.post_aoj).to eq false
          end
        end

        context "when legacy" do
          let(:document_type) { Constants::APPEAL_DECISION_TYPES["DRAFT_DECISION"] }
          let(:work_product) { "Decision" }
          let(:vacated_issue) { FactoryBot.create(:case_issue, :disposition_vacated) }
          let(:remand_reason) { FactoryBot.create(:remand_reason, rmdval: "AB", rmddev: "R2") }
          let(:remanded_issue) do
            FactoryBot.create(:case_issue, :disposition_remanded, remand_reasons: [remand_reason])
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

          context "when all parameters are present for draft decision and VACOLS update is successful" do
            let(:decass_record) do
              VACOLS::Decass.find_by(defolder: subject.vacols_id, deadtim: subject.created_in_vacols_date)
            end

            it "should create DraftDecision record" do
              expect(decass_record.deprod).to eq QueueMapper.work_product_to_vacols_code(
                work_product, params[:overtime]
              )
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

          context "when all parameters are present for Draft Decision but Vacols update is not successful" do
            let(:issues) do
              [{ disposition: case_issues[0].issdc, vacols_sequence_id: "1000" }]
            end

            it "should not create DraftDecision record" do
              expect { subject }.to raise_error(Caseflow::Error::IssueRepositoryError)
              expect(AttorneyCaseReview.count).to eq 0
            end
          end

          context "when all parameters are present for Draft Decision but issues are not sent" do
            let(:issues) { nil }

            it "should create Draft Decision record" do
              expect(subject.document_type).to eq Constants::APPEAL_DECISION_TYPES["DRAFT_DECISION"]
              expect(subject.valid?).to eq true
              expect(subject.work_product).to eq "Decision"
              expect(subject.document_id).to eq document_id
              expect(subject.note).to eq note
              expect(subject.reviewing_judge).to eq judge
              expect(subject.attorney).to eq attorney
              expect(subject.issues).to eq nil
            end
          end
        end
      end
    end
  end
end
