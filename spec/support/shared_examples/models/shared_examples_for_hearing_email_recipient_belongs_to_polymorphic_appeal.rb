# frozen_string_literal: true

require "query_subscriber"

# @param claimant_subclass [Class] a subclass of `HearingEmailRecipient`
shared_examples "HearingEmailRecipient belongs_to polymorphic appeal" do |hearing_email_recipient_subclass|
  context do
    context "'appeal'-related associations" do
      it { should belong_to(:appeal) }
      it { should belong_to(:ama_appeal).class_name("Appeal").with_foreign_key(:appeal_id).optional }
      it { should belong_to(:legacy_appeal).class_name("LegacyAppeal").with_foreign_key(:appeal_id).optional }

      describe "ama_appeal" do
        context "when used in `joins` query" do
          subject { hearing_email_recipient_subclass.joins(:ama_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99999 }
          let!(:_legacy_hearing_email_recipient) do
            create(:hearing_email_recipient, type: hearing_email_recipient_subclass.to_s,
                                             appeal: create(:legacy_appeal, id: shared_id))
          end

          context "when there are no HearingEmailRecipients with AMA appeals" do
            it { should be_none }
          end

          context "when there are HearingEmailRecipients with AMA appeals" do
            let!(:ama_hearing_email_recipient) do
              create(:hearing_email_recipient, type: hearing_email_recipient_subclass.to_s,
                                               appeal: create(:appeal, id: shared_id))
            end

            it { should contain_exactly(ama_hearing_email_recipient) }
          end
        end

        context "when eager loading with `includes`" do
          subject { hearing_email_recipient_subclass.ama.includes(:appeal) }

          let!(:_legacy_hearing_email_recipient) do
            create(:hearing_email_recipient, :legacy, type: hearing_email_recipient_subclass.to_s)
          end

          context "when there are no HearingEmailRecipients with AMA appeals" do
            it { should be_none }
          end

          context "when there are HearingEmailRecipients with AMA appeals" do
            let!(:ama_hearing_email_recipients) do
              create_list(:hearing_email_recipient, 10, :ama, type: hearing_email_recipient_subclass.to_s)
            end

            it { should contain_exactly(*ama_hearing_email_recipients) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { hearing_email_recipient_subclass.ama.preload(:appeal) }

          let!(:_legacy_hearing_email_recipient) do
            create(:hearing_email_recipient, :legacy, type: hearing_email_recipient_subclass.to_s)
          end

          context "when there are no HearingEmailRecipients with AMA appeals" do
            it { should be_none }
          end

          context "when there are HearingEmailRecipients with AMA appeals" do
            let!(:ama_hearing_email_recipients) do
              create_list(:hearing_email_recipient, 10, :ama, type: hearing_email_recipient_subclass.to_s)
            end

            it { should contain_exactly(*ama_hearing_email_recipients) }

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
          subject { hearing_email_recipient_subclass.joins(:legacy_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99999 }
          let!(:_ama_hearing_email_recipient) do
            create(:hearing_email_recipient, type: hearing_email_recipient_subclass.to_s,
                                             appeal: create(:appeal, id: shared_id))
          end

          context "when there are no HearingEmailRecipients with Legacy appeals" do
            it { should be_none }
          end

          context "when there are HearingEmailRecipients with Legacy appeals" do
            let!(:legacy_hearing_email_recipient) do
              create(:hearing_email_recipient, type: hearing_email_recipient_subclass.to_s,
                                               appeal: create(:legacy_appeal, id: shared_id))
            end

            it { should contain_exactly(legacy_hearing_email_recipient) }
          end
        end

        context "when eager loading with `includes`" do
          subject { hearing_email_recipient_subclass.legacy.includes(:appeal) }

          let!(:_ama_hearing_email_recipient) do
            create(:hearing_email_recipient, :ama, type: hearing_email_recipient_subclass.to_s)
          end

          context "when there are no HearingEmailRecipients with Legacy appeals" do
            it { should be_none }
          end

          context "when there are HearingEmailRecipients with Legacy appeals" do
            let!(:legacy_hearing_email_recipients) do
              create_list(:hearing_email_recipient, 10, :legacy, type: hearing_email_recipient_subclass.to_s)
            end

            it { should contain_exactly(*legacy_hearing_email_recipients) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { hearing_email_recipient_subclass.legacy.preload(:appeal) }

          let!(:_ama_hearing_email_recipient) do
            create(:hearing_email_recipient, :ama, type: hearing_email_recipient_subclass.to_s)
          end

          context "when there are no HearingEmailRecipients with Legacy appeals" do
            it { should be_none }
          end

          context "when there are HearingEmailRecipients with Legacy appeals" do
            let!(:legacy_hearing_email_recipients) do
              create_list(:hearing_email_recipient, 10, :legacy, type: hearing_email_recipient_subclass.to_s)
            end

            it { should contain_exactly(*legacy_hearing_email_recipients) }

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
      let!(:ama_hearing_email_recipients) do
        create_list(:hearing_email_recipient, 2, :ama, type: hearing_email_recipient_subclass.to_s)
      end
      let!(:legacy_hearing_email_recipients) do
        create_list(:hearing_email_recipient, 2, :legacy, type: hearing_email_recipient_subclass.to_s)
      end

      describe ".ama" do
        it "returns only HearingEmailRecipients belonging to AMA appeals" do
          expect(hearing_email_recipient_subclass.ama).to be_an(ActiveRecord::Relation)
          expect(hearing_email_recipient_subclass.ama).to contain_exactly(*ama_hearing_email_recipients)
        end
      end

      describe ".legacy" do
        it "returns only HearingEmailRecipients belonging to Legacy appeals" do
          expect(hearing_email_recipient_subclass.legacy).to be_an(ActiveRecord::Relation)
          expect(hearing_email_recipient_subclass.legacy).to contain_exactly(*legacy_hearing_email_recipients)
        end
      end
    end
  end
end
