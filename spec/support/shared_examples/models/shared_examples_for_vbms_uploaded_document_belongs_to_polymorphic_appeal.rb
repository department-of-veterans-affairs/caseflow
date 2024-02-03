# frozen_string_literal: true

require "query_subscriber"

shared_examples "VbmsUploadedDocument belongs_to polymorphic appeal" do
  context do
    context "'appeal'-related associations" do
      it { should belong_to(:appeal) }
      it { should belong_to(:ama_appeal).class_name("Appeal").with_foreign_key(:appeal_id).optional }
      it { should belong_to(:legacy_appeal).class_name("LegacyAppeal").with_foreign_key(:appeal_id).optional }

      describe "ama_appeal" do
        context "when used in `joins` query" do
          subject { VbmsUploadedDocument.joins(:ama_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99_999 }
          let!(:_legacy_vbms_uploaded_document) do
            create(:vbms_uploaded_document, appeal: create(:legacy_appeal, vacols_case: create(:case), id: shared_id))
          end

          context "when there are no VbmsUploadedDocument with AMA appeals" do
            it { should be_none }
          end

          context "when there are VbmsUploadedDocument with AMA appeals" do
            let!(:ama_vbms_uploaded_document) do
              create(:vbms_uploaded_document, appeal: create(:appeal, id: shared_id))
            end

            it { should contain_exactly(ama_vbms_uploaded_document) }
          end
        end

        context "when eager loading with `includes`" do
          subject { VbmsUploadedDocument.ama.includes(:appeal) }

          let!(:_legacy_vbms_uploaded_document) { create(:vbms_uploaded_document, :legacy) }

          context "when there are no VbmsUploadedDocument with AMA appeals" do
            it { should be_none }
          end

          context "when there are VbmsUploadedDocument with AMA appeals" do
            let!(:ama_vbms_uploaded_documents) { create_list(:vbms_uploaded_document, 10, :ama) }

            it { should contain_exactly(*ama_vbms_uploaded_documents) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { VbmsUploadedDocument.ama.preload(:appeal) }

          let!(:_legacy_vbms_uploaded_document) { create(:vbms_uploaded_document, :legacy) }

          context "when there are no VbmsUploadedDocument with AMA appeals" do
            it { should be_none }
          end

          context "when there are VbmsUploadedDocument with AMA appeals" do
            let!(:ama_vbms_uploaded_documents) { create_list(:vbms_uploaded_document, 10, :ama) }

            it { should contain_exactly(*ama_vbms_uploaded_documents) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end
      end

      describe "legacy_appeal" do
        context "when used in `joins` query" do
          subject { VbmsUploadedDocument.joins(:legacy_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99_999 }
          let!(:_ama_vbms_uploaded_document) { create(:vbms_uploaded_document, appeal: create(:appeal, id: shared_id)) }

          context "when there are no VbmsUploadedDocument with Legacy appeals" do
            it { should be_none }
          end

          context "when there are VbmsUploadedDocument with Legacy appeals" do
            let!(:legacy_vbms_uploaded_document) do
              create(:vbms_uploaded_document, appeal: create(:legacy_appeal, vacols_case: create(:case), id: shared_id))
            end

            it { should contain_exactly(legacy_vbms_uploaded_document) }
          end
        end

        context "when eager loading with `includes`" do
          subject { VbmsUploadedDocument.legacy.includes(:appeal) }

          let!(:_ama_vbms_uploaded_document) { create(:vbms_uploaded_document, :ama) }

          context "when there are no VbmsUploadedDocument with Legacy appeals" do
            it { should be_none }
          end

          context "when there are VbmsUploadedDocument with Legacy appeals" do
            let!(:legacy_vbms_uploaded_documents) { create_list(:vbms_uploaded_document, 10, :legacy) }

            it { should contain_exactly(*legacy_vbms_uploaded_documents) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { VbmsUploadedDocument.legacy.preload(:appeal) }

          let!(:_ama_vbms_uploaded_document) { create(:vbms_uploaded_document, :ama) }

          context "when there are no VbmsUploadedDocument with Legacy appeals" do
            it { should be_none }
          end

          context "when there are VbmsUploadedDocument with Legacy appeals" do
            let!(:legacy_vbms_uploaded_documents) { create_list(:vbms_uploaded_document, 10, :legacy) }

            it { should contain_exactly(*legacy_vbms_uploaded_documents) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end
      end
    end

    context "'appeal'-related scopes" do
      let!(:ama_vbms_uploaded_documents) { create_list(:vbms_uploaded_document, 2, :ama) }
      let!(:legacy_vbms_uploaded_documents) { create_list(:vbms_uploaded_document, 2, :legacy) }

      describe ".ama" do
        it "returns only VbmsUploadedDocument belonging to AMA appeals" do
          expect(VbmsUploadedDocument.ama).to be_an(ActiveRecord::Relation)
          expect(VbmsUploadedDocument.ama).to contain_exactly(*ama_vbms_uploaded_documents)
        end
      end

      describe ".legacy" do
        it "returns only VbmsUploadedDocument belonging to Legacy appeals" do
          expect(VbmsUploadedDocument.legacy).to be_an(ActiveRecord::Relation)
          expect(VbmsUploadedDocument.legacy).to contain_exactly(*legacy_vbms_uploaded_documents)
        end
      end
    end
  end
end
