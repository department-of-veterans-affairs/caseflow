describe AttorneyCaseReview do
  let(:attorney) { FactoryBot.create(:user) }
  let(:judge) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID) }

  before { FeatureToggle.enable!(:test_facols) }
  after { FeatureToggle.disable!(:test_facols) }

  context ".complete" do
    let!(:vacols_atty) { FactoryBot.create(:staff, :attorney_role, sdomainid: attorney.css_id) }
    let!(:vacols_judge) { FactoryBot.create(:staff, :judge_role, sdomainid: judge.css_id) }
    let(:case_issues) { [] }
    let(:vacols_case) { FactoryBot.create(:case, :assigned, staff: vacols_atty, case_issues: case_issues) }
    let(:document_type) { Constants::APPEAL_DECISION_TYPES["OMO_REQUEST"] }
    let(:work_product) { "OMO - IME" }
    let(:document_id) { "123456789.1234" }
    let(:note) { "something" }
    let(:task_id) { "#{vacols_case.bfkey}-#{vacols_case.decass[0].deadtim.strftime('%F')}" }
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

    context "should validate format of the task ID" do
      context "when correct format" do
        it { is_expected.to be_valid }
      end

      context "when correct format with letters" do
        let(:case_id_w_trailing_letter) { "1989L" }
        let(:vacols_case) { FactoryBot.create(:case, :assigned, staff: vacols_atty, bfkey: case_id_w_trailing_letter) }
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
      let(:document_type) { Constants::APPEAL_DECISION_TYPES["DRAFT_DECISION"] }
      let(:work_product) { "Decision" }
      let(:vacated_issue) { FactoryBot.create(:case_issue, :disposition_vacated) }
      let(:remand_reason) { FactoryBot.create(:remand_reason, rmdval: "AB", rmddev: "R2") }
      let(:remanded_issue) { FactoryBot.create(:case_issue, :disposition_remanded, remand_reasons: [remand_reason]) }
      let(:case_issues) { [vacated_issue, remanded_issue] }
      let(:issues) do
        [
          { disposition: case_issues[0].issdc,
            vacols_sequence_id: case_issues[0].issseq,
            readjudication: true },
          { disposition: case_issues[1].issdc,
            vacols_sequence_id: case_issues[1].issseq,
            remand_reasons: [{ code: remand_reason.rmdval, after_certification: true }] }
        ]
      end

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

      context "when all parameters are present for draft decision and VACOLS update is successful" do
        let(:decass_record) do
          VACOLS::Decass.find_by(defolder: subject.vacols_id, deadtim: subject.created_in_vacols_date)
        end

        it "should create DraftDecision record" do
          expect(decass_record.deprod).to eq QueueMapper.work_product_to_vacols_code(work_product, params[:overtime])
          expect(decass_record.deatcom).to eq note
          expect(decass_record.dedocid).to eq document_id
        end

        it "should update the location for the associated VACOLS::Case with the Judge's VACOLS ID" do
          expect(decass_record.case.bfcurloc).to eq judge.vacols_uniq_id
        end

        # TODO: We don't currently test that the most recent PRIORLOC record (prior to this action) is updated with a
        # LOCDIN date and LOCSTRCV staffer because we aren't yet creating PRIORLOC records when we create BRIEFF records
        # through FactoryBot. Add a test to confirm we are correctly updating that PRIORLOC record when we add this
        # functionality to the BRIEFF factory. Link to untested segment of code below:
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
