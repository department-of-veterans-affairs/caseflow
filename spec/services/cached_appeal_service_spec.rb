# frozen_string_literal: true

describe CachedAppealService do
  subject { described_class.new }

  context "caches hearing_request_type and former_travel correctly" do
    let(:vacols_case) { create(:case, :travel_board_hearing) }
    let(:legacy_appeal) do # former travel, currently virtual
      create(
        :legacy_appeal,
        vacols_case: vacols_case,
        changed_hearing_request_type: HearingDay::REQUEST_TYPES[:virtual]
      )
    end

    it "caches hearing_request_type correctly", :aggregate_failures do
      subject.cache_legacy_appeal_postgres_data([legacy_appeal])
      subject.cache_legacy_appeal_vacols_data([vacols_case.bfkey])

      expect(CachedAppeal.find_by(vacols_id: legacy_appeal.vacols_id).hearing_request_type).to eq("Virtual")
    end

    it "caches former_travel correctly", :aggregate_failures do
      subject.cache_legacy_appeal_postgres_data([legacy_appeal])
      subject.cache_legacy_appeal_vacols_data([vacols_case.bfkey])

      expect(CachedAppeal.find_by(vacols_id: legacy_appeal.vacols_id).former_travel).to eq(true)
    end
  end

  context "cached appeal was recently updated" do
    let(:ama_appeal) { create(:appeal) }
    let(:vacols_case) { create(:case, :travel_board_hearing) }
    let(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
    let(:future_time) { Time.now.utc + 10.minutes }
    let!(:legacy_existing_cached_appeal) do
      create(
        :cached_appeal,
        appeal_id: legacy_appeal.id,
        appeal_type: LegacyAppeal.name,
        updated_at: future_time # simulates a possible race condition, but not realistic
      )
    end
    let!(:ama_existing_cached_appeal) do
      create(
        :cached_appeal,
        appeal_id: ama_appeal.id,
        appeal_type: Appeal.name,
        updated_at: future_time # simulates a possible race condition, but not realistic
      )
    end

    it "does not update appeals that were recently cached" do
      subject.cache_ama_appeals([ama_appeal])
      subject.cache_legacy_appeal_postgres_data([legacy_appeal])
      subject.cache_legacy_appeal_vacols_data([vacols_case.bfkey])

      legacy_cached_appeal = CachedAppeal.find_by(appeal_id: legacy_appeal.id, appeal_type: LegacyAppeal.name)
      ama_cached_appeal = CachedAppeal.find_by(appeal_id: ama_appeal.id, appeal_type: Appeal.name)

      # updated_at shouldn't change
      expect(legacy_cached_appeal.updated_at.utc).to be_within(1.in_milliseconds).of(future_time)
      expect(ama_cached_appeal.updated_at.utc).to be_within(1.in_milliseconds).of(future_time)
    end
  end
end
