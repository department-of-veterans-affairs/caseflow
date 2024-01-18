# frozen_string_literal: true

require "query_subscriber"

shared_examples "AppealState belongs_to polymorphic appeal" do
  context do
    let!(:_user) { create(:user) } # A User needs to exist for `appeal_state` factories

    context "'appeal'-related associations" do
      it { should belong_to(:appeal) }
      it { should belong_to(:ama_appeal).class_name("Appeal").with_foreign_key(:appeal_id).optional }
      it { should belong_to(:legacy_appeal).class_name("LegacyAppeal").with_foreign_key(:appeal_id).optional }

      describe "ama_appeal" do
        context "when used in `joins` query" do
          subject { AppealState.joins(:ama_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 1 }
          let!(:_legacy_appeal_state) { create(:appeal_state, appeal: create(:legacy_appeal, id: shared_id)) }

          context "when there are no AppealStates with AMA appeals" do
            it { should be_none }
          end

          context "when there are AppealStates with AMA appeals" do
            let!(:ama_appeal_state) { create(:appeal_state, appeal: create(:appeal, id: shared_id)) }

            it { should contain_exactly(ama_appeal_state) }
          end
        end

        context "when eager loading with `includes`" do
          subject { AppealState.ama.includes(:ama_appeal) }

          let!(:_legacy_appeal_state) { create(:appeal_state, :legacy) }

          context "when there are no AppealStates with AMA appeals" do
            it { should be_none }
          end

          context "when there are AppealStates with AMA appeals" do
            let!(:ama_appeal_states) { create_list(:appeal_state, 10, :ama) }

            it { should contain_exactly(*ama_appeal_states) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.ama_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { AppealState.ama.preload(:ama_appeal) }

          let!(:_legacy_appeal_state) { create(:appeal_state, :legacy) }

          context "when there are no AppealStates with AMA appeals" do
            it { should be_none }
          end

          context "when there are AppealStates with AMA appeals" do
            let!(:ama_appeal_states) { create_list(:appeal_state, 10, :ama) }

            it { should contain_exactly(*ama_appeal_states) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.ama_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when called on an individual AppealState" do
          subject { appeal_state.ama_appeal }

          context "when the AppealState is not associated with an AMA appeal" do
            let(:appeal_state) { create(:appeal_state, :legacy) }

            it { should be_nil }
          end

          context "when the appeal_state is associated with an AMA appeal" do
            let(:appeal_state) { create(:appeal_state, appeal: ama_appeal) }
            let(:ama_appeal) { create(:appeal) }

            it { should eq(ama_appeal) }
          end
        end
      end

      describe "legacy_appeal" do
        context "when used in `joins` query" do
          subject { AppealState.joins(:legacy_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 1 }
          let!(:_ama_appeal_state) { create(:appeal_state, appeal: create(:appeal, id: shared_id)) }

          context "when there are no AppealStates with Legacy appeals" do
            it { should be_none }
          end

          context "when there are AppealStates with Legacy appeals" do
            let!(:legacy_appeal_state) { create(:appeal_state, appeal: create(:legacy_appeal, id: shared_id)) }

            it { should contain_exactly(legacy_appeal_state) }
          end
        end

        context "when eager loading with `includes`" do
          subject { AppealState.legacy.includes(:legacy_appeal) }

          let!(:_ama_appeal_state) { create(:appeal_state, :ama) }

          context "when there are no AppealStates with Legacy appeals" do
            it { should be_none }
          end

          context "when there are AppealStates with Legacy appeals" do
            let!(:legacy_appeal_states) { create_list(:appeal_state, 10, :legacy) }

            it { should contain_exactly(*legacy_appeal_states) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.legacy_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { AppealState.legacy.preload(:legacy_appeal) }

          let!(:_ama_appeal_state) { create(:appeal_state, :ama) }

          context "when there are no AppealStates with Legacy appeals" do
            it { should be_none }
          end

          context "when there are AppealStates with Legacy appeals" do
            let!(:legacy_appeal_states) { create_list(:appeal_state, 10, :legacy) }

            it { should contain_exactly(*legacy_appeal_states) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.legacy_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when called on an individual AppealState" do
          subject { appeal_state.legacy_appeal }

          context "when the AppealState is not associated with a Legacy appeal" do
            let(:appeal_state) { create(:appeal_state, :ama) }

            it { should be_nil }
          end

          context "when the appeal_state is associated with a Legacy appeal" do
            let(:appeal_state) { create(:appeal_state, appeal: legacy_appeal) }
            let(:legacy_appeal) { create(:legacy_appeal) }

            it { should eq(legacy_appeal) }
          end
        end
      end
    end

    context "'appeal'-related scopes" do
      let!(:ama_appeal_states) { create_list(:appeal_state, 2, :ama) }
      let!(:legacy_appeal_states) { create_list(:appeal_state, 2, :legacy) }

      describe ".ama" do
        it "returns only AppealStates belonging to AMA appeals" do
          expect(AppealState.ama).to be_an(ActiveRecord::Relation)
          expect(AppealState.ama).to contain_exactly(*ama_appeal_states)
        end
      end

      describe ".legacy" do
        it "returns only AppealStates belonging to Legacy appeals" do
          expect(AppealState.legacy).to be_an(ActiveRecord::Relation)
          expect(AppealState.legacy).to contain_exactly(*legacy_appeal_states)
        end
      end
    end
  end
end
