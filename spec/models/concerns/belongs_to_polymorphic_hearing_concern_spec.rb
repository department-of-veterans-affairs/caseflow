# frozen_string_literal: true

require "query_subscriber"

describe BelongsToPolymorphicHearingConcern do
  let!(:ama_sent_hearing_email_event) { create(:sent_hearing_email_event, :ama) }
  let!(:legacy_sent_hearing_email_event) { create(:sent_hearing_email_event, :legacy) }
  let!(:hearing_email_recipient) { create(:hearing_email_recipient, hearing: create(:hearing)) }
  let!(:legacy_hearing_email_recipient) { create(:hearing_email_recipient, hearing: create(:legacy_hearing)) }

  context "concern is included in SentHearingEmailEvent" do
    it "`ama_hearing` returns the AMA hearing" do
      expect(ama_sent_hearing_email_event.ama_hearing).to eq ama_sent_hearing_email_event.hearing
    end

    it "`legacy_hearing` returns the legacy hearing" do
      expect(legacy_sent_hearing_email_event.legacy_hearing).to eq legacy_sent_hearing_email_event.hearing
    end
  end
end
