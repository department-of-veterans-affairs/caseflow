describe AttorneyCaseReview do
  let(:judge) { User.create(css_id: "CFS123", station_id: User::BOARD_STATION_ID) }
  let(:attorney) { User.create(css_id: "CFS456", station_id: "317") }

  before do
    Fakes::Initializer.load!
  end

  context ".create" do
    subject { AttorneyCaseReview.create(params) }
    context "should validate format of the task ID" do
      let(:params) do
        {
          type: "OMORequest",
          reviewing_judge: judge,
          work_product: "OMO - IME",
          document_id: "123456789.1234",
          overtime: true,
          note: "something",
          task_id: task_id,
          attorney: attorney
        }
      end
      context "when correct format" do
        let(:task_id) { "123456-2013-12-06" }
        it { is_expected.to be_valid }
      end

      context "when incorrect format" do
        let(:task_id) { "123456-2013/12/06" }
        it { is_expected.to_not be_valid }
      end
    end
  end

  context ".complete!" do
    subject { AttorneyCaseReview.complete!(params) }

    context "when all parameters are present for OMO Request and Vacols update is successful" do
      before do
        allow(Fakes::QueueRepository).to receive(:reassign_case_to_judge!).with(
          vacols_id: "123456",
          created_in_vacols_date: "2013-12-06".to_date,
          judge_vacols_user_id: judge.vacols_uniq_id,
          decass_attrs: {
            work_product: "OMO - IME",
            document_id: "123456789.1234",
            overtime: true,
            modifying_user: "CFS456",
            note: "something"
          }
        ).and_return(true)

        expect(Fakes::IssueRepository).to_not receive(:update_vacols_issue!)
      end

      let(:params) do
        {
          type: "OMORequest",
          reviewing_judge: judge,
          work_product: "OMO - IME",
          document_id: "123456789.1234",
          overtime: true,
          note: "something",
          task_id: "123456-2013-12-06",
          attorney: attorney
        }
      end

      it "should create OMORequest record" do
        expect(subject.class).to eq OMORequest
        expect(subject.valid?).to eq true
        expect(subject.work_product).to eq "OMO - IME"
        expect(subject.document_id).to eq "123456789.1234"
        expect(subject.note).to eq "something"
        expect(subject.reviewing_judge).to eq judge
        expect(subject.attorney).to eq attorney
      end
    end

    context "when all parameters are present for Draft Decision and Vacols update is successful" do
      before do
        allow(Fakes::QueueRepository).to receive(:reassign_case_to_judge!).with(
          vacols_id: "123456",
          created_in_vacols_date: "2013-12-06".to_date,
          judge_vacols_user_id: judge.vacols_uniq_id,
          decass_attrs: {
            work_product: "Decision",
            document_id: "123456789.1234",
            overtime: true,
            note: "something",
            modifying_user: "CFS456"
          }
        ).and_return(true)

        expect(Fakes::IssueRepository).to receive(:update_vacols_issue!).with(
          vacols_id: "123456",
          vacols_sequence_id: 1,
          issue_attrs: {
            vacols_user_id: attorney.vacols_uniq_id,
            disposition: "Vacated",
            disposition_date: VacolsHelper.local_date_with_utc_timezone,
            readjudication: true,
            remand_reasons: nil
          }
        ).once

        expect(Fakes::IssueRepository).to receive(:update_vacols_issue!).with(
          vacols_id: "123456",
          vacols_sequence_id: 2,
          issue_attrs: {
            vacols_user_id: attorney.vacols_uniq_id,
            disposition: "Remanded",
            disposition_date: VacolsHelper.local_date_with_utc_timezone,
            readjudication: nil,
            remand_reasons: [{ code: "AB", after_certification: true }]
          }
        ).once
      end

      let(:params) do
        {
          type: "DraftDecision",
          reviewing_judge: judge,
          work_product: "Decision",
          document_id: "123456789.1234",
          overtime: true,
          note: "something",
          task_id: "123456-2013-12-06",
          attorney: attorney,
          issues: issues
        }
      end
      let(:issues) do
        [
          { disposition: "Vacated", vacols_sequence_id: 1, readjudication: true },
          { disposition: "Remanded", vacols_sequence_id: 2,
            remand_reasons: [{ code: "AB", after_certification: true }] }
        ]
      end

      it "should create DraftDecision record" do
        expect(subject.class).to eq DraftDecision
        expect(subject.valid?).to eq true
        expect(subject.work_product).to eq "Decision"
        expect(subject.document_id).to eq "123456789.1234"
        expect(subject.note).to eq "something"
        expect(subject.reviewing_judge).to eq judge
        expect(subject.attorney).to eq attorney
        expect(subject.issues).to eq issues
      end
    end

    context "when not all required parameters are present and Vacols update is successful" do
      before do
        allow(Fakes::QueueRepository).to receive(:reassign_case_to_judge!).and_return(true)
      end

      let(:params) do
        {
          reviewing_judge: judge,
          work_product: "OMO - IME",
          document_id: "123456789.1234",
          overtime: true,
          note: "something",
          task_id: "123456-2013-12-06",
          attorney: attorney
        }
      end

      it "should not create AttorneyCaseReview record" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        expect(AttorneyCaseReview.count).to eq 0
      end
    end

    context "when all parameters are present for OMO Request but Vacols update is not successful" do
      before do
        allow(Fakes::QueueRepository).to receive(:reassign_case_to_judge!)
          .and_raise(Caseflow::Error::QueueRepositoryError)
      end

      let(:params) do
        {
          type: "OMORequest",
          reviewing_judge: judge,
          work_product: "OMO - IME",
          document_id: "123456789.1234",
          overtime: true,
          note: "something",
          task_id: "123456-2013-12-06",
          attorney: attorney
        }
      end

      it "should not create OMORequest record" do
        expect { subject }.to raise_error(Caseflow::Error::QueueRepositoryError)
        expect(AttorneyCaseReview.count).to eq 0
      end
    end

    context "when all parameters are present for Draft Decision but Vacols update is not successful" do
      before do
        allow(Fakes::QueueRepository).to receive(:reassign_case_to_judge!).and_return(true)
        allow(Fakes::IssueRepository).to receive(:update_vacols_issue!).and_raise(Caseflow::Error::IssueRepositoryError)
      end

      let(:params) do
        {
          type: "DraftDecision",
          reviewing_judge: judge,
          work_product: "Decision",
          document_id: "123456789.1234",
          overtime: true,
          note: "something",
          task_id: "123456-2013-12-06",
          attorney: attorney,
          issues: issues
        }
      end
      let(:issues) do
        [{ disposition: "Allowed", vacols_sequence_id: 1 }, { disposition: "Remanded", vacols_sequence_id: 2 }]
      end

      it "should not create DraftDecision record" do
        expect { subject }.to raise_error(Caseflow::Error::IssueRepositoryError)
        expect(AttorneyCaseReview.count).to eq 0
      end
    end

    context "when all parameters are present for Draft Decision but issues are not sent" do
      before do
        allow(Fakes::QueueRepository).to receive(:reassign_case_to_judge!).and_return(true)
        expect(Fakes::IssueRepository).to_not receive(:update_vacols_issue!)
      end

      let(:params) do
        {
          type: "DraftDecision",
          reviewing_judge: judge,
          work_product: "Decision",
          document_id: "123456789.1234",
          overtime: true,
          note: "something",
          task_id: "123456-2013-12-06",
          attorney: attorney
        }
      end

      it "should create DraftDecision record" do
        expect(subject.class).to eq DraftDecision
        expect(subject.valid?).to eq true
        expect(subject.work_product).to eq "Decision"
        expect(subject.document_id).to eq "123456789.1234"
        expect(subject.note).to eq "something"
        expect(subject.reviewing_judge).to eq judge
        expect(subject.attorney).to eq attorney
        expect(subject.issues).to eq nil
      end
    end
  end
end
