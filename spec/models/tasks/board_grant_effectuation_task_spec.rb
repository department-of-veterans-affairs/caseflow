describe BoardGrantEffectuationTask do
  let(:task_status) { "assigned" }
  let(:task) { create(:board_grant_effectuation_task, status: task_status).becomes(described_class) }

  context "#label" do
    subject { task.label }

    it "has a label of Board Grant" do
      expect(subject).to eq "Board Grant"
    end
  end

  describe "#complete_with_payload!" do
    subject { task.complete_with_payload!(nil, nil) }

    context "assigned task" do
      it "can be completed" do
        expect(subject).to eq true
        task.reload
        expect(task.status).to eq "completed"
      end
    end

    context "completed task" do
      let(:task_status) { "completed" }

      it "cannot be completed again" do
        expect(subject).to eq false
      end
    end
  end

  describe "#appeal_ui_hash" do
    let(:veteran) { create(:veteran) }
    let(:appeal) { create(:appeal, veteran_file_number: veteran.file_number) }
    let!(:education_business_line) { create(:business_line, url: "education") }
    let(:education_task) do
      create(:task, appeal: appeal, assigned_to: education_business_line).becomes(described_class)
    end

    context "appeal with request issues in multiple business lines" do
      let!(:insurance_business_line) { create(:business_line, url: "insurance") }
      let!(:education_request_issue) do
        create(:request_issue, :nonrating, review_request: appeal, benefit_type: "education")
      end
      let!(:insurance_request_issue) do
        create(:request_issue, :nonrating, review_request: appeal, benefit_type: "insurance")
      end
      let(:insurance_task) do
        create(:task, appeal: appeal, assigned_to: insurance_business_line).becomes(described_class)
      end

      it "only shows request issues relevant to business line" do
        education_task_issues = education_task.appeal_ui_hash[:requestIssues]
        insurance_task_issues = insurance_task.appeal_ui_hash[:requestIssues]

        expect(education_task_issues.length).to eq(1)
        expect(insurance_task_issues.length).to eq(1)
        expect(education_task_issues.first[:id]).to eq(education_request_issue.id)
        expect(insurance_task_issues.first[:id]).to eq(insurance_request_issue.id)
      end
    end

    context "appeal with request issues in one business line" do
      let!(:education_request_issues) do
        [
          create(:request_issue, :nonrating, review_request: appeal, benefit_type: "education"),
          create(:request_issue, :nonrating, review_request: appeal, benefit_type: "education")
        ]
      end

      it "shows all request issues" do
        education_task_issues = education_task.appeal_ui_hash[:requestIssues]
        expect(education_task_issues.length).to eq(2)
      end
    end
  end
end
