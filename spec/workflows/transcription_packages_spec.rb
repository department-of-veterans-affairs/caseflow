# frozen_string_literal: true

describe TranscriptionPackages do
  describe "#call" do
    context "start to execute all jobs" do
      let(:hearings) {(1..5).map{ create(:hearing, :with_transcription_files)}}
      let(:legacy_hearings) {(1..5).map{ create(:hearing, :with_transcription_files)}}
      let(:work_order) do
        {
          work_order_name: "#1234567",
          return_date: "05/07/2024",
          contractor: "Contractor A",
          hearings_list: hearings + legacy_hearings
        }
      end
      subject { TranscriptionPackages.new(work_order).call }


      it "Call to initialize method" do
        subject.create_work_order
      end


    end
  end
end
