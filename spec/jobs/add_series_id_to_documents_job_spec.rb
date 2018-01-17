require "rails_helper"

describe AddSeriesIdToDocumentsJob do
  context ".perform" do
    let(:appeal) do
      Generators::Appeal.build
    end

    let(:series_ids) do
      (0..4).map do |_|
        SecureRandom.uuid
      end
    end

    context "appeal has documents without series_ids" do
      before do
        expect(VBMSService).to receive(:fetch_document_series_for).with(appeal.sanitized_vbms_id).and_return(
          version_ids.zip(series_ids).map do |version_id_array, series_id|
            index = 0
            version_id_array.map do |version_id|
              index += 1
              OpenStruct.new(
                vbms_filename: "test_file",
                type_id: Caseflow::DocumentTypes::TYPES.keys.sample,
                document_id: version_id,
                version_id: version_id,
                series_id: series_id,
                version: index,
                mime_type: "application/pdf",
                received_at: rand(100).days.ago,
                downloaded_from: "VBMS"
              )
            end
          end
        )
      end

      let!(:documents_without_series) do
        (0..4).map do |index|
          Generators::Document.create(
            file_number: appeal.sanitized_vbms_id,
            series_id: nil,
            vbms_document_id: version_ids[index].sample
          )
        end
      end

      let(:version_ids) do
        (0..4).map do |_|
          (0..rand(5)).map do
            SecureRandom.uuid
          end
        end
      end

      let!(:vva_document) do
        Generators::Document.create(
          file_number: appeal.sanitized_vbms_id,
          series_id: nil,
          vbms_document_id: SecureRandom.uuid
        )
      end

      it "assigns series_ids to documents without them" do
        AddSeriesIdToDocumentsJob.perform_now(appeal)

        documents_without_series.zip(series_ids).each do |document, series_id|
          expect(document.reload.series_id).to eq(series_id)
        end

        # VVA docs get their vbms_document_id as their series id
        expect(vva_document.reload.series_id).to eq(vva_document.vbms_document_id)
      end
    end

    context "appeal has documents with series_ids" do
      before do
        expect(VBMSService).to_not receive(:fetch_document_series_for)
      end

      let!(:documents_with_series) do
        (0..4).map do |index|
          Generators::Document.create(file_number: appeal.sanitized_vbms_id, series_id: series_ids[index])
        end
      end

      it "documents with series ids are not touched" do
        AddSeriesIdToDocumentsJob.perform_now(appeal)

        documents_with_series.zip(series_ids).each do |document, series_id|
          expect(document.reload.series_id).to eq(series_id)
        end
      end
    end
  end
end
