describe HearingWorksheet do
  context ".update" do
    subject { worksheet.update(worksheet_hash) }
    let(:worksheet) { Generators::HearingWorksheet.build }
    let(:issue) { worksheet.hearing.appeal.issues.first }
    let(:worksheet_hash) do
      {
        military_service: "Vietnam 1968 - 1970",
        hearing_worksheet_issues_attributes: [
          { status: :remand, vha: true, issue_id: issue.id }
        ]
      }
    end

    it "updates nested attributes (issues)" do
      expect(worksheet.issues.count).to eq(0)
      subject # do update
      expect(worksheet.issues.count).to eq(1)

      expect(worksheet.issues.first.status).to eq("remand")
      expect(worksheet.issues.first.vha).to be_truthy

      # test that a 2nd save updates the same record, rather than create new one
      worksheet_issue_id = worksheet.issues.first.id
      worksheet_hash[:hearing_worksheet_issues_attributes][0][:status] = :deny
      worksheet_hash[:hearing_worksheet_issues_attributes][0][:id] = worksheet_issue_id

      worksheet.update(worksheet_hash)

      expect(worksheet.issues.count).to eq(1)
      expect(worksheet.issues.first.id).to eq(worksheet_issue_id)
      expect(worksheet.issues.first.status).to eq("deny")
    end
  end
end
