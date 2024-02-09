# frozen_string_literal: true

require "query_subscriber"

shared_examples "AvailableHearingLocations belongs_to polymorphic appeal" do
  context do
    context "'appeal'-related associations" do
      it { should belong_to(:appeal) }
      it { should belong_to(:ama_appeal).class_name("Appeal").with_foreign_key(:appeal_id).optional }
      it { should belong_to(:legacy_appeal).class_name("LegacyAppeal").with_foreign_key(:appeal_id).optional }

      describe "ama_appeal" do
        context "when used in `joins` query" do
          subject { AvailableHearingLocations.joins(:ama_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99_999 }
          let!(:_legacy_available_hearing_locations) do
            create(:available_hearing_locations,
                   appeal: create(:legacy_appeal, vacols_case: create(:case), id: shared_id))
          end

          context "when there are no AvailableHearingLocations with AMA appeals" do
            it { should be_none }
          end

          context "when there are AvailableHearingLocations with AMA appeals" do
            let!(:ama_available_hearing_locations) do
              create(:available_hearing_locations, appeal: create(:appeal, id: shared_id))
            end

            it { should contain_exactly(ama_available_hearing_locations) }
          end
        end

        context "when eager loading with `includes`" do
          subject { AvailableHearingLocations.ama.includes(:appeal) }

          let!(:_legacy_available_hearing_locations) { create(:available_hearing_locations, :legacy) }

          context "when there are no AvailableHearingLocations with AMA appeals" do
            it { should be_none }
          end

          context "when there are AvailableHearingLocations with AMA appeals" do
            let!(:ama_available_hearing_locations) { create_list(:available_hearing_locations, 10, :ama) }

            it { should contain_exactly(*ama_available_hearing_locations) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { AvailableHearingLocations.ama.preload(:appeal) }

          let!(:_legacy_available_hearing_locations) { create(:available_hearing_locations, :legacy) }

          context "when there are no AvailableHearingLocations with AMA appeals" do
            it { should be_none }
          end

          context "when there are AvailableHearingLocations with AMA appeals" do
            let!(:ama_available_hearing_locations) { create_list(:available_hearing_locations, 10, :ama) }

            it { should contain_exactly(*ama_available_hearing_locations) }

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
          subject { AvailableHearingLocations.joins(:legacy_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99_999 }
          let!(:_ama_available_hearing_locations) do
            create(:available_hearing_locations, appeal: create(:appeal, id: shared_id))
          end

          context "when there are no AvailableHearingLocations with Legacy appeals" do
            it { should be_none }
          end

          context "when there are AvailableHearingLocations with Legacy appeals" do
            let!(:legacy_available_hearing_locations) do
              create(:available_hearing_locations,
                     appeal: create(:legacy_appeal, vacols_case: create(:case), id: shared_id))
            end

            it { should contain_exactly(legacy_available_hearing_locations) }
          end
        end

        context "when eager loading with `includes`" do
          subject { AvailableHearingLocations.legacy.includes(:appeal) }

          let!(:_ama_available_hearing_locations) { create(:available_hearing_locations, :ama) }

          context "when there are no AvailableHearingLocations with Legacy appeals" do
            it { should be_none }
          end

          context "when there are AvailableHearingLocations with Legacy appeals" do
            let!(:legacy_available_hearing_locations) { create_list(:available_hearing_locations, 10, :legacy) }

            it { should contain_exactly(*legacy_available_hearing_locations) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { AvailableHearingLocations.legacy.preload(:appeal) }

          let!(:_ama_available_hearing_locations) { create(:available_hearing_locations, :ama) }

          context "when there are no AvailableHearingLocations with Legacy appeals" do
            it { should be_none }
          end

          context "when there are AvailableHearingLocations with Legacy appeals" do
            let!(:legacy_available_hearing_locations) { create_list(:available_hearing_locations, 10, :legacy) }

            it { should contain_exactly(*legacy_available_hearing_locations) }

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
      let!(:ama_available_hearing_locations) { create_list(:available_hearing_locations, 2, :ama) }
      let!(:legacy_available_hearing_locations) { create_list(:available_hearing_locations, 2, :legacy) }

      describe ".ama" do
        it "returns only AvailableHearingLocations belonging to AMA appeals" do
          expect(AvailableHearingLocations.ama).to be_an(ActiveRecord::Relation)
          expect(AvailableHearingLocations.ama).to contain_exactly(*ama_available_hearing_locations)
        end
      end

      describe ".legacy" do
        it "returns only AvailableHearingLocations belonging to Legacy appeals" do
          expect(AvailableHearingLocations.legacy).to be_an(ActiveRecord::Relation)
          expect(AvailableHearingLocations.legacy).to contain_exactly(*legacy_available_hearing_locations)
        end
      end
    end
  end
end
