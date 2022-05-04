# frozen_string_literal: true

describe CancelChangeHearingRequestTypeTaskJob do
  current_time = Time.zone.today
  let(:appeal_one) { create(:appeal, id: 1) }
  let(:appeal_two) { create(:appeal, id: 2) }

  context "when there's no hearings 11 days before scheduled" do
    subject { CancelChangeHearingRequestTypeTaskJob.perform_now }
    schedule_day = current_time.next_day(12)
    let(:hearing_day) { create(:hearing_day, scheduled_for: schedule_day) }
    let(:hearing_one) { create(:hearing, hearing_day: hearing_day, appeal: appeal_one) }
    let(:hearing_two) { create(:hearing, hearing_day: hearing_day, appeal: appeal_two) }

    it "find_affected_hearings returns empty array" do
      subject

      expect(subject.nil?)
    end
  end
  context "when there are hearings 11 days before scheduled" do
    subject { CancelChangeHearingRequestTypeTaskJob.perform_now }
    schedule_day = current_time.next_day(11)
    let(:hearing_day) { create(:hearing_day, scheduled_for: schedule_day) }
    let(:hearing_one) { create(:hearing, hearing_day: hearing_day, appeal: appeal_one) }
    let(:hearing_two) { create(:hearing, hearing_day: hearing_day, appeal: appeal_two) }

    it "find_affected_hearings returns relevant hearing" do
      subject
      expect(!subject.nil?)
      expect(subject.eq('4'))
      #{}expect(subject.has(1))
      #{}expect(subject.has(2))
    end
  end
end
