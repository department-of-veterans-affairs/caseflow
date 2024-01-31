# frozen_string_literal: true

require "query_subscriber"

shared_examples "SentHearingEmailEvent belongs_to polymorphic hearing" do
  context do
    context "'hearing'-related associations" do
      it { should belong_to(:hearing) }
      it { should belong_to(:ama_hearing).class_name("Hearing").with_foreign_key(:hearing_id).optional }
      it { should belong_to(:legacy_hearing).class_name("LegacyHearing").with_foreign_key(:hearing_id).optional }

      describe "ama_hearing" do
        context "when used in `joins` query" do
          subject { SentHearingEmailEvent.joins(:ama_hearing) }

          # Create records having different `hearing_type` but the same `hearing_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `hearing_id` but
          # different `hearing_type`.
          let(:shared_id) { 99999 }
          let!(:_legacy_sent_hearing_email_event) do
            create(:sent_hearing_email_event, hearing: create(:legacy_hearing, id: shared_id))
          end

          context "when there are no SentHearingEmailEvent with AMA hearings" do
            it { should be_none }
          end

          context "when there are SentHearingEmailEvent with AMA hearings" do
            let!(:ama_sent_hearing_email_event) do
              create(:sent_hearing_email_event, hearing: create(:hearing, id: shared_id))
            end

            it { should contain_exactly(ama_sent_hearing_email_event) }
          end
        end

        context "when eager loading with `includes`" do
          subject { SentHearingEmailEvent.ama.includes(:ama_hearing) }

          let!(:_legacy_sent_hearing_email_event) { create(:sent_hearing_email_event, :legacy) }

          context "when there are no SentHearingEmailEvent with AMA hearings" do
            it { should be_none }
          end

          context "when there are SentHearingEmailEvent with AMA hearings" do
            let!(:ama_sent_hearing_email_events) { create_list(:sent_hearing_email_event, 10, :ama) }

            it { should contain_exactly(*ama_sent_hearing_email_events) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.ama_hearing.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { SentHearingEmailEvent.ama.preload(:ama_hearing) }

          let!(:_legacy_sent_hearing_email_event) { create(:sent_hearing_email_event, :legacy) }

          context "when there are no SentHearingEmailEvent with AMA hearings" do
            it { should be_none }
          end

          context "when there are SentHearingEmailEvent with AMA hearings" do
            let!(:ama_sent_hearing_email_events) { create_list(:sent_hearing_email_event, 10, :ama) }

            it { should contain_exactly(*ama_sent_hearing_email_events) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.ama_hearing.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when called on an individual SentHearingEmailEvent" do
          subject { sent_hearing_email_event.ama_hearing }

          context "when the SentHearingEmailEvent is not associated with an AMA hearing" do
            let(:sent_hearing_email_event) { create(:sent_hearing_email_event, :legacy) }

            it { should be_nil }
          end

          context "when the SentHearingEmailEvent is associated with an AMA hearing" do
            let(:sent_hearing_email_event) { create(:sent_hearing_email_event, hearing: ama_hearing) }
            let(:ama_hearing) { create(:hearing) }

            it { should eq(ama_hearing) }
          end
        end
      end

      describe "legacy_hearing" do
        context "when used in `joins` query" do
          subject { SentHearingEmailEvent.joins(:legacy_hearing) }

          # Create records having different `hearing_type` but the same `hearing_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `hearing_id` but
          # different `hearing_type`.
          let(:shared_id) { 99999 }
          let!(:_ama_sent_hearing_email_event) do
            create(:sent_hearing_email_event, hearing: create(:hearing, id: shared_id))
          end

          context "when there are no SentHearingEmailEvent with Legacy hearings" do
            it { should be_none }
          end

          context "when there are SentHearingEmailEvent with Legacy hearings" do
            let!(:legacy_sent_hearing_email_event) do
              create(:sent_hearing_email_event, hearing: create(:legacy_hearing, id: shared_id))
            end

            it { should contain_exactly(legacy_sent_hearing_email_event) }
          end
        end

        context "when eager loading with `includes`" do
          subject { SentHearingEmailEvent.legacy.includes(:legacy_hearing) }

          let!(:_ama_sent_hearing_email_event) { create(:sent_hearing_email_event, :ama) }

          context "when there are no SentHearingEmailEvent with Legacy hearings" do
            it { should be_none }
          end

          context "when there are SentHearingEmailEvent with Legacy hearings" do
            let!(:legacy_sent_hearing_email_events) { create_list(:sent_hearing_email_event, 10, :legacy) }

            it { should contain_exactly(*legacy_sent_hearing_email_events) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.legacy_hearing.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { SentHearingEmailEvent.legacy.preload(:legacy_hearing) }

          let!(:_ama_sent_hearing_email_event) { create(:sent_hearing_email_event, :ama) }

          context "when there are no SentHearingEmailEvent with Legacy hearings" do
            it { should be_none }
          end

          context "when there are SentHearingEmailEvent with Legacy hearings" do
            let!(:legacy_sent_hearing_email_events) { create_list(:sent_hearing_email_event, 10, :legacy) }

            it { should contain_exactly(*legacy_sent_hearing_email_events) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.legacy_hearing.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when called on an individual SentHearingEmailEvent" do
          subject { sent_hearing_email_event.legacy_hearing }

          context "when the SentHearingEmailEvent is not associated with a Legacy hearing" do
            let(:sent_hearing_email_event) { create(:sent_hearing_email_event, :ama) }

            it { should be_nil }
          end

          context "when the SentHearingEmailEvent is associated with a Legacy hearing" do
            let(:sent_hearing_email_event) { create(:sent_hearing_email_event, hearing: legacy_hearing) }
            let(:legacy_hearing) { create(:legacy_hearing) }

            it { should eq(legacy_hearing) }
          end
        end
      end
    end

    context "'hearing'-related scopes" do
      let!(:ama_sent_hearing_email_events) { create_list(:sent_hearing_email_event, 2, :ama) }
      let!(:legacy_sent_hearing_email_events) { create_list(:sent_hearing_email_event, 2, :legacy) }

      describe ".ama" do
        it "returns only SentHearingEmailEvent belonging to AMA hearings" do
          expect(SentHearingEmailEvent.ama).to be_an(ActiveRecord::Relation)
          expect(SentHearingEmailEvent.ama).to contain_exactly(*ama_sent_hearing_email_events)
        end
      end

      describe ".legacy" do
        it "returns only SentHearingEmailEvent belonging to Legacy hearings" do
          expect(SentHearingEmailEvent.legacy).to be_an(ActiveRecord::Relation)
          expect(SentHearingEmailEvent.legacy).to contain_exactly(*legacy_sent_hearing_email_events)
        end
      end
    end
  end
end
