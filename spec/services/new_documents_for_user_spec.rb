describe NewDocumentsForUser do
  let(:appeal) { Generators::LegacyAppeal.build }
  let(:user) { create(:user) }

  context "#process!" do
    before do
      documents.each { |document| document.update(file_number: appeal.veteran_file_number) }
    end

    context "query_vbms = true" do
      before do
        expect(EFolderService).to receive(:fetch_documents_for).and_return(doc_struct).once
      end

      let!(:documents) do
        [
          create(:document, upload_date: Time.parse("2019-03-01 12:00:00 -0500")),
          create(:document, upload_date: Time.parse("2019-03-01 12:00:00 -0500"))
        ]
      end

      let(:service_manifest_vbms_fetched_at) { Time.zone.local(1989, "nov", 23, 8, 2, 55) }
      let(:service_manifest_vva_fetched_at) { Time.zone.local(1989, "dec", 13, 20, 15, 1) }

      let(:fetched_at_format) { "%D %l:%M%P %Z %z" }
      let!(:efolder_fetched_at_format) { "%FT%T.%LZ" }
      let(:doc_struct) do
        {
          documents: documents,
          manifest_vbms_fetched_at: service_manifest_vbms_fetched_at.utc.strftime(efolder_fetched_at_format),
          manifest_vva_fetched_at: service_manifest_vva_fetched_at.utc.strftime(efolder_fetched_at_format)
        }
      end

      let(:new_documents_for_user) do
        NewDocumentsForUser.new(appeal: appeal, user: user, query_vbms: true, date_to_compare_with: Time.zone.at(0))
      end

      subject { new_documents_for_user.process! }

      context "when appeal has no appeal view" do
        it "should return all documents" do
          expect(subject).to match_array(documents)
        end
      end

      context "when appeal has an appeal view newer than documents" do
        let!(:appeal_view) { AppealView.create(appeal: appeal, user: user, last_viewed_at: Time.zone.now) }

        it "should return no documents" do
          expect(subject).to eq([])
        end

        context "when one document is missing a received at date" do
          it "should return no documents" do
            documents[0].update(upload_date: nil)
            expect(subject).to eq([])
          end
        end

        context "when one document is newer than the appeal view date" do
          it "should return the newer document" do
            documents[0].update(upload_date: Time.parse("2019-03-07 12:00:00 -0500"))
            expect(subject).to eq([documents[0]])
          end
        end
      end
    end

    context "query_vbms = false" do
      before do
        expect(EFolderService).not_to receive(:fetch_documents_for)
      end

      let!(:documents) do
        [
          Generators::Document.create(upload_date: Time.parse("2019-03-01 12:00:00 -0500")),
          Generators::Document.create(upload_date: Time.parse("2019-03-01 12:00:00 -0500"))
        ]
      end

      context "when no alternative date is provided" do
        let(:new_documents_for_user) do
          NewDocumentsForUser.new(appeal: appeal, user: user, query_vbms: false, date_to_compare_with: Time.zone.at(0))
        end

        subject { new_documents_for_user.process! }

        context "when appeal has no appeal view" do
          it "should return all documents" do
            expect(subject).to match_array(documents)
          end
        end

        context "when appeal has an appeal view newer than documents" do
          let!(:appeal_view) { AppealView.create(appeal: appeal, user: user, last_viewed_at: Time.zone.now) }

          it "should return no documents" do
            expect(subject).to eq([])
          end

          context "when one document is missing a received at date" do
            it "should return no documents" do
              documents[0].update(upload_date: nil)
              expect(subject).to eq([])
            end
          end

          context "when one document is newer than the appeal view date" do
            it "should return the newer document" do
              documents[0].update(upload_date: Time.parse("2019-03-07 12:00:00 -0500"))
              expect(subject).to eq([documents[0]])
            end
          end
        end
      end

      context "when providing an on_hold date" do
        let(:new_documents_for_user) do
          NewDocumentsForUser.new(appeal: appeal, user: user, query_vbms: false, date_to_compare_with: Time.parse("2019-03-02 12:00:00 -0500"))
        end

        subject { new_documents_for_user.process! }

        context "When one document's upload date is after on hold date" do
          it "should return only the newest document" do
            documents[0].update(upload_date: Time.parse("2019-03-03 12:00:00 -0500"))
            expect(subject).to eq([documents[0]])
          end
        end

        context "when appeal has an appeal view newer than the on hold date" do
          let!(:appeal_view) { AppealView.create(appeal: appeal, user: user, last_viewed_at: Time.parse("2019-03-04 12:00:00 -0500")) }

          it "should return no documents" do
            expect(subject).to eq([])
          end

          context "when one document's upload date is after the last viewed date" do
            it "should return the document uploaded after the view, but not the one after the hold date" do
              documents[1].update(upload_date: Time.parse("2019-03-05 12:00:00 -0500"))
              expect(subject).to eq([documents[1]])
            end
          end
        end
      end
    end
  end
end
