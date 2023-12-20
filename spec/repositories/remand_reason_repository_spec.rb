# frozen_string_literal: true

describe RemandReasonRepository, :all_dbs do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  after do
    Timecop.return
  end

  context ".load_remand_reasons_for_appeals" do
    subject { RemandReasonRepository.load_remand_reasons_for_appeals(vacols_ids) }

    let!(:vacols_case1) { create(:case, case_issues: issues1) }
    let(:issues1) { [create(:case_issue, :disposition_remanded), create(:case_issue, :disposition_remanded)] }

    let!(:vacols_case2) { create(:case, case_issues: issues2) }
    let(:issues2) { [create(:case_issue, :disposition_allowed)] }

    let!(:vacols_case3) { create(:case, case_issues: issues3) }
    let(:issues3) do
      [create(:case_issue, :disposition_remanded),
       create(:case_issue, :disposition_allowed),
       create(:case_issue, :disposition_remanded)]
    end

    let!(:remand_reasons) do
      [
        create(:remand_reason,
               rmdkey: issues1.second.isskey,
               rmdissseq: issues1.second.issseq,
               rmdval: "BA", rmddev: "R1"),
        create(:remand_reason,
               rmdkey: issues3.first.isskey,
               rmdissseq: issues3.first.issseq,
               rmdval: "AA"),
        create(:remand_reason,
               rmdkey: issues3.first.isskey,
               rmdissseq: issues3.first.issseq,
               rmdval: "AB",
               rmddev: "R1"),
        create(:remand_reason, rmdkey: issues3.third.isskey, rmdissseq: issues3.third.issseq, rmdval: "AC")
      ]
    end

    let(:vacols_ids) { [vacols_case1.bfkey, vacols_case2.bfkey, vacols_case3.bfkey] }

    let(:result) do
      { vacols_case1.bfkey => { issues1.second.issseq => [{ code: "BA", post_aoj: false }] },
        vacols_case2.bfkey => {},
        vacols_case3.bfkey =>
          { issues3.first.issseq =>
             [{ code: "AA", post_aoj: true }, { code: "AB", post_aoj: false }],
            issues3.third.issseq => [{ code: "AC", post_aoj: true }] } }
    end

    it "should load remand reasons per appeal" do
      expect(subject).to eq result
    end
  end

  context ".update_remand_reasons" do
    subject { RemandReasonRepository.update_remand_reasons(record, issue_attrs) }
    let(:record) do
      OpenStruct.new(issdc: initial_disposition)
    end

    let(:issue_attrs) do
      {
        disposition: disposition,
        vacols_user_id: "TEST1",
        readjudication: nil,
        vacols_sequence_id: "3",
        vacols_id: "123456",
        remand_reasons: [{ code: "AB", post_aoj: true }]
      }
    end

    context "when disposition is not changed from remanded" do
      let(:initial_disposition) { "3" }
      let(:disposition) { "3" }
      let(:remand_reasons) { create(:remand_reason) }

      it "does not create new remand reasons" do
        remand_reasons.save!
        expect(RemandReasonRepository).to_not receive(:create_remand_reasons!)
        subject
      end

      it "updates existing remand reasons" do
        expect(RemandReasonRepository).to receive(:update_remand_reasons!)
        subject
      end
    end

    context "when disposition is changed to remanded" do
      let(:initial_disposition) { nil }
      let(:disposition) { "3" }
      let(:remand_reasons) do
        [{
          rmdval: "AB",
          rmddev: "R2",
          rmdmdusr: "TEST1",
          rmdmdtim: VacolsHelper.local_time_with_utc_timezone
        }]
      end

      it "creates remand reasons" do
        expect(RemandReasonRepository).to receive(:create_remand_reasons!)
          .with("123456", "3", remand_reasons).once
        expect(BusinessMetrics).to_not receive(:record)
        subject
      end

      context "when remand reasons are not passed" do
        let(:initial_disposition) { nil }
        let(:disposition) { "3" }

        let(:issue_attrs) do
          {
            disposition: "3",
            vacols_user_id: "TEST1",
            readjudication: nil,
            vacols_sequence_id: "3",
            vacols_id: "123456",
            remand_reasons: []
          }
        end

        it "throws an error" do
          expect { subject }.to raise_error(Caseflow::Error::RemandReasonRepositoryError)
        end
      end
    end

    context "when disposition is changed from remanded" do
      let(:initial_disposition) { "3" }
      let(:disposition) { "Allowed" }

      it "deletes existing remand reasons" do
        expect(RemandReasonRepository).to receive(:delete_remand_reasons!)
        subject
      end
    end
  end

  context ".create_remand_reasons!" do
    subject { RemandReasonRepository.create_remand_reasons!(vacols_id, vacols_sequence_id, remand_reasons) }
    let(:vacols_id) { "123456" }
    let(:vacols_sequence_id) { "3" }
    let(:remand_reasons) do
      [{
        rmdval: "AB",
        rmddev: "R2",
        rmdmdusr: "TEST1",
        rmdmdtim: VacolsHelper.local_time_with_utc_timezone
      }]
    end

    it "creates remand reasons" do
      subject
      expect(VACOLS::RemandReason.all.length).to eq(1)

      remand_reason = VACOLS::RemandReason.all.first
      expect(remand_reason.rmdval).to eq "AB"
      expect(remand_reason.rmddev).to eq "R2"
      expect(remand_reason.rmdissseq).to eq 3
      expect(remand_reason.rmdkey).to eq "123456"
    end
  end

  context ".delete_remand_reasons!" do
    subject { RemandReasonRepository.delete_remand_reasons!(vacols_id, vacols_sequence_id, **kwargs) }
    let(:vacols_id) { "123456" }
    let(:vacols_sequence_id) { "3" }
    let!(:remand_reasons) do
      [
        create(:remand_reason),
        create(:remand_reason, rmdval: "DI"),
        create(:remand_reason, rmdval: "AA")
      ]
    end

    context "deletes a specific remand reason" do
      let(:kwargs) { { rmdval: "DI" } }

      it "deletes a specific remand reason" do
        subject
        expect(VACOLS::RemandReason.all.length).to eq(2)
        expect(VACOLS::RemandReason.all.map(&:rmdval)).to_not include "DI"
      end
    end

    context "deletes all remand reasons for an issue" do
      let(:kwargs) { {} }

      it "deletes all remand reasons for an issue" do
        subject
        expect(VACOLS::RemandReason.all.length).to eq(0)
      end
    end
  end
end
