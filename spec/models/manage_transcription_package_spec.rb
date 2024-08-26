# frozen_string_literal: true

RSpec.describe ManageTranscriptionPackage, type: :model do
  let(:task_number) { "TASK123" }
  let(:current_user) { create(:user) }

  before do
    allow_any_instance_of(ManageTranscriptionPackage).to receive(:current_user).and_return(current_user)
  end

  describe ".display_wo_summary" do
    let(:wo_info) do
      {
        "return_date" => "2024-01-01",
        "work_order" => task_number,
        "contractor_name" => "Contractor X"
      }
    end

    let(:wo_file_info) do
      {
        "wo_file_info" => [
          {
            "docket_number" => "D123",
            "case_type" => "Type A",
            "hearing_date" => "2024-01-01",
            "first_name" => "John",
            "last_name" => "Doe",
            "judge_name" => "Judge Judy",
            "regional_office" => "RO City",
            "types" => "Type 1, Type 2"
          }
        ]
      }
    end

    before do
      allow(ManageTranscriptionPackage).to receive(:fetch_wo_info).with(task_number).and_return(wo_info)
      allow(ManageTranscriptionPackage).to receive(:fetch_wo_file_info).with(task_number).and_return(wo_file_info)
    end

    it "returns the merged work order summary" do
      result = ManageTranscriptionPackage.display_wo_summary(task_number)
      expect(result).to eq(wo_info.merge(wo_file_info))
    end
  end

  describe ".display_wo_contents" do
    let(:transcription) do
      Transcription.create!(task_number: task_number)
    end

    let(:transcription_file) do
      file = TranscriptionFile.new(docket_number: "D123", transcription: transcription)
      allow(file).to receive(:case_details).and_return("Details of case")
      file
    end

    before do
      allow(Transcription).to receive(:includes).and_return(Transcription)
      allow(Transcription).to receive(:find_by).with(task_number: task_number).and_return(transcription)
      allow(transcription).to receive(:transcription_files).and_return([transcription_file])
    end

    it "returns work order contents" do
      result = ManageTranscriptionPackage.display_wo_contents(task_number)
      expect(result).to eq([
                             {
                               case_details: transcription_file.case_details,
                               docket_number: transcription_file.docket_number
                             }
                           ])
    end
  end

  describe ".unassign_wo" do
    let(:task_number) { "TASK123" }

    let!(:transcription_package) do
      TranscriptionPackage.create!(task_number: task_number, status: "Assigned")
    end

    let!(:transcription) do
      Transcription.create!(task_number: task_number)
    end

    let!(:transcription_file) do
      file = create(:transcription_file, transcription: transcription)
      allow(file).to receive(:case_details).and_return("Details of case")
      file
    end

    before do
      allow(ManageTranscriptionPackage).to receive(:update_transcription_package).with(task_number).and_return(true)
      allow(ManageTranscriptionPackage).to receive(:update_transcription_info).with(task_number).and_return(true)
      allow(ManageTranscriptionPackage).to receive(:get_banner_messages)
        .with(task_number)
        .and_return(
          hearing_message: "Some hearing message",
          work_order_message: "Work order message for Contractor X"
        )
    end

    it "updates the transcription package and returns banner messages" do
      result = ManageTranscriptionPackage.unassign_wo(task_number)
      expected_result = {
        hearing_message: "Some hearing message",
        work_order_message: "Work order message for Contractor X"
      }
      expect(result).to eq(expected_result)
    end
  end
end
