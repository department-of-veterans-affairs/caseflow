describe IssueRepository do
  context ".perform_actions_if_disposition_changes" do
    subject { IssueRepository.perform_actions_if_disposition_changes(record, issue_attrs) }
    let(:record) do
      OpenStruct.new(
        attributes_for_readjudication: {
          program: "02",
          issue: "01",
          level_1: "03",
          level_2: nil,
          level_3: nil,
          vacols_id: "123456",
          note: "note"
        },
        issdc: initial_disposition
      )
    end

    let(:issue_attrs) do
      {
        disposition: disposition,
        vacols_user_id: "TEST1",
        readjudication: readjudication,
        vacols_sequence_id: "3",
        vacols_id: "123456",
        remand_reasons: [{ code: "AB", after_certification: true }]
      }
    end

    context "when disposition is not changed" do
      let(:initial_disposition) { nil }
      let(:disposition) { nil }
      let(:readjudication) { nil }

      it "sends business metrics" do
        expect(BusinessMetrics).to receive(:record)
          .with(service: :queue, name: "non_disposition_issue_edit").once
        subject
      end
    end

    context "when disposition is changed to remanded" do
      let(:initial_disposition) { nil }
      let(:disposition) { "3" }
      let(:readjudication) { nil }
      let(:remand_reasons) do
        [{
          rmdval: "AB",
          rmddev: "R2",
          rmdmdusr: "TEST1",
          rmdmdtim: VacolsHelper.local_time_with_utc_timezone
        }]
      end

      it "creates remand reasons" do
        expect(IssueRepository).to receive(:create_remand_reasons!)
          .with("123456", "3", remand_reasons).once
        expect(BusinessMetrics).to_not receive(:record)
        subject
      end
    end

    context "when disposition is not changed from remanded" do
      let(:initial_disposition) { "3" }
      let(:disposition) { "3" }
      let(:readjudication) { nil }
      let(:remand_reason) { create(:remand_reason) }

      it "does not create new remand reasons" do
        expect(IssueRepository).to_not receive(:create_remand_reasons!)
        subject
      end

      it "updates existing remand reasons" do
        expect(IssueRepository).to receive(:update_remand_reasons!)
        subject
      end
    end

    context "when disposition is changed from remanded" do
      let(:initial_disposition) { "3" }
      let(:disposition) { "Allowed" }
      let(:readjudication) { nil }

      it "deletes existing remand reasons" do
        expect(IssueRepository).to receive(:delete_remand_reasons!)
        subject
      end
    end

    context "when disposition is changed to vacated and readjudication is selected" do
      let(:initial_disposition) { nil }
      let(:disposition) { "5" }
      let(:readjudication) { true }
      let(:result_params) do
        {
          program: "02",
          issue: "01",
          level_1: "03",
          level_2: nil,
          level_3: nil,
          vacols_id: "123456",
          note: "note",
          vacols_user_id: "TEST1"
        }
      end

      it "creates a duplicate issue" do
        expect(IssueRepository).to receive(:create_vacols_issue!)
          .with(issue_attrs: result_params).once
        subject
      end
    end

    context "when disposition is changed to vacated and readjudication is not selected" do
      let(:initial_disposition) { nil }
      let(:disposition) { "5" }
      let(:readjudication) { false }

      it "does not create a duplicate issue" do
        expect(IssueRepository).to_not receive(:create_vacols_issue!)
        subject
      end
    end

    context "when disposition is not changed but readjudication is selected" do
      let(:initial_disposition) { "5" }
      let(:disposition) { "5" }
      let(:readjudication) { true }

      it "does not create a duplicate issue" do
        expect(IssueRepository).to_not receive(:create_vacols_issue!)
        subject
      end
    end
  end
end
