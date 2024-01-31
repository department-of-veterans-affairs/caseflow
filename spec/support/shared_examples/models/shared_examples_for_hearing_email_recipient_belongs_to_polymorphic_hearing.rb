# frozen_string_literal: true

require "query_subscriber"

# @param hearing_email_recipient_subclass [Class] a subclass of `HearingEmailRecipient`
shared_examples "HearingEmailRecipient belongs_to polymorphic hearing" do |hearing_email_recipient_subclass|
  context do
    context "'hearing'-related associations" do
      it { should belong_to(:hearing) }
      it { should belong_to(:ama_hearing).class_name("Hearing").with_foreign_key(:hearing_id).optional }
      it { should belong_to(:legacy_hearing).class_name("LegacyHearing").with_foreign_key(:hearing_id).optional }

      describe "ama_hearing" do
        context "when used in `joins` query" do
          subject { hearing_email_recipient_subclass.joins(:ama_hearing) }

          # Create records having different `hearing_type` but the same `hearing_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `hearing_id` but
          # different `hearing_type`.
          let(:shared_id) { 99999 }
          let!(:_legacy_hearing_email_recipient) do
            create(:hearing_email_recipient, type: hearing_email_recipient_subclass.to_s,
                                             hearing: create(:legacy_hearing, id: shared_id))
          end

          context "when there are no HearingEmailRecipients with AMA Hearings" do
            it { should be_none }
          end

          context "when there are HearingEmailRecipients with AMA Hearings" do
            let!(:ama_hearing_email_recipient) do
              create(:hearing_email_recipient, type: hearing_email_recipient_subclass.to_s,
                                               hearing: create(:hearing, id: shared_id))
            end

            it { should contain_exactly(ama_hearing_email_recipient) }
          end
        end

        context "when called on an individual HearingEmailRecipients" do
          subject { hearing_email_recipient.ama_hearing }

          context "when the HearingEmailRecipients is not associated with an AMA Hearing" do
            let(:hearing_email_recipient) { create(:hearing_email_recipient, :legacy) }

            it { should be_nil }
          end

          context "when the HearingEmailRecipients is associated with an AMA Hearing" do
            let(:hearing_email_recipient) { create(:hearing_email_recipient, :ama, hearing: ama_hearing) }
            let(:ama_hearing) { create(:hearing) }

            it { should eq(ama_hearing) }
          end
        end
      end

      describe "legacy_hearing" do
        context "when used in `joins` query" do
          subject { hearing_email_recipient_subclass.joins(:legacy_hearing) }

          # Create records having different `hearing_type` but the same `hearing_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `hearing_id` but
          # different `hearing_type`.
          let(:shared_id) { 99999 }
          let!(:_ama_hearing_email_recipient) do
            create(:hearing_email_recipient, type: hearing_email_recipient_subclass.to_s,
                                             hearing: create(:hearing, id: shared_id))
          end

          context "when there are no HearingEmailRecipients with LegacyHearings" do
            it { should be_none }
          end

          context "when there are HearingEmailRecipients with LegacyHearings" do
            let!(:legacy_hearing_email_recipient) do
              create(:hearing_email_recipient, type: hearing_email_recipient_subclass.to_s,
                                               hearing: create(:legacy_hearing, id: shared_id))
            end

            it { should contain_exactly(legacy_hearing_email_recipient) }
          end
        end

        context "when called on an individual HearingEmailRecipients" do
          subject { hearing_email_recipient.ama_hearing }

          context "when the HearingEmailRecipient is not associated with an AMA Hearing" do
            let(:hearing_email_recipient) { create(:hearing_email_recipient, :legacy) }

            it { should be_nil }
          end

          context "when the HearingEmailRecipient is associated with an AMA Hearing" do
            let(:hearing_email_recipient) { create(:hearing_email_recipient, :ama, hearing: ama_hearing) }
            let(:ama_hearing) { create(:hearing) }

            it { should eq(ama_hearing) }
          end
        end
      end
    end
  end
end
