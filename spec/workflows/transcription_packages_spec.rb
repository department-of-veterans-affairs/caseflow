# frozen_string_literal: true

describe TranscriptionPackages do
  describe "#call" do
    context "start to execute all jobs" do
      let(:hearings) { (1..5).map { create(:hearing, :with_transcription_files) } }
      let(:legacy_hearings) { (1..5).map { create(:hearing, :with_transcription_files) } }

      def hearings_in_work_order(all_hearings)
        all_hearings.map { |hearing| { hearing_id: hearing.id, hearing_type: hearing.class.to_s } }
      end

      let(:work_order_params) do
        {
          work_order_name: "#1234567",
          return_date: "05/07/2024",
          contractor: "Contractor A",
          hearings: hearings_in_work_order(hearings + legacy_hearings)
        }
      end

      let(:transcription_package) { create(:transcription_package) }

      subject { TranscriptionPackages.new(work_order_params) }

      it "Call to initialize method" do
        expect(subject.instance_variable_get(:@work_order_params)[:work_order_name]).to eq("#1234567")
        expect(subject.instance_variable_get(:@work_order_params)[:return_date]).to eq("05/07/2024")
        expect(subject.instance_variable_get(:@work_order_params)[:contractor]).to eq("Contractor A")
        expect(subject.instance_variable_get(:@work_order_params)[:hearings]).to eq(
          hearings_in_work_order(hearings + legacy_hearings)
        )
      end

      it "Call to call method" do
        allow_any_instance_of(TranscriptionPackages).to receive(:create_zip_file).and_return(true)
        allow_any_instance_of(TranscriptionPackages).to receive(:create_bom_file).and_return(true)
        allow_any_instance_of(TranscriptionPackages).to receive(:zip_and_upload_transcription_package).and_return(true)
        allow_any_instance_of(TranscriptionPackages).to receive(:upload_transcription_package).and_return(true)
        expect { subject.call }.not_to raise_error
      end

      it "Call to upload_transcription_package method" do
        expect(Hearings::VaBoxUploadJob).to receive(:perform_now).with(transcription_package)
        subject.upload_transcription_package(transcription_package)
      end
    end
  end
end
