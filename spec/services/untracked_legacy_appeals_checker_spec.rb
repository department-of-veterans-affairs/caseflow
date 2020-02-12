# frozen_string_literal: true

describe UntrackedLegacyAppealsChecker, :all_dbs do
  context "when there are LegacyAppeals charged to CASEFLOW in VACOLS without active Caseflow tasks" do
    let(:untracked_legacy_appeals) do
      Array.new(3) { create(:legacy_appeal, vacols_case: create(:case)) }
    end
    let(:tracked_legacy_appeals) do
      Array.new(4) { create(:legacy_appeal, vacols_case: create(:case)) }
    end

    before do
      # Set the VACOLS location code to CASEFLOW for all legacy appeals.
      [untracked_legacy_appeals, tracked_legacy_appeals].flatten.each do |appeal|
        VACOLS::Case.find_by(bfkey: appeal.vacols_id).update!(bfcurloc: LegacyAppeal::LOCATION_CODES[:caseflow])
      end

      # Only create tasks for tracked legacy appeals.
      tracked_legacy_appeals.each do |appeal|
        create(:ama_task, assigned_to: create(:user), appeal: appeal)
      end
    end

    describe "#call" do
      it "builds a report that includes the IDs of the untracked legacy appeals to Slack" do
        subject.call

        expect(subject.report).to match(/#{untracked_legacy_appeals.pluck(:id).sort}/)
      end
    end
  end

  context "when all LegacyAppeals charged to CASEFLOW in VACOLS have active Caseflow tasks" do
    let(:tracked_legacy_appeals) do
      Array.new(5) { create(:legacy_appeal, vacols_case: create(:case)) }
    end

    before do
      tracked_legacy_appeals.each do |appeal|
        VACOLS::Case.find_by(bfkey: appeal.vacols_id).update!(bfcurloc: LegacyAppeal::LOCATION_CODES[:caseflow])
        create(:ama_task, assigned_to: create(:user), appeal: appeal)
      end
    end

    describe "#call" do
      it "does not build a report" do
        subject.call

        expect(subject.report?).to be_falsey
      end
    end
  end
end
