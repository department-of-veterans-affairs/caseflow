# frozen_string_literal: true

require_relative "../../app/helpers/sync_decided_appeals_helper"

describe "SyncDecidedAppealsHelper" do
  self.use_transactional_tests = false

  class Helper
    include SyncDecidedAppealsHelper
  end

  attr_reader :helper

  subject do
    Helper.new
  end

  context "#sync_decided_appeals" do
    let(:decided_appeal_state) do
      create_decided_appeal_state_with_case_record_and_hearing(true, true)
    end

    let(:undecided_appeal_state) do
      create_decided_appeal_state_with_case_record_and_hearing(false, true)
    end

    let(:missing_vacols_case_appeal_state) do
      create_decided_appeal_state_with_case_record_and_hearing(true, false)
    end

    it "Job syncs decided appeals decision_mailed status", bypass_cleaner: true do
      expect([decided_appeal_state,
              undecided_appeal_state,
              missing_vacols_case_appeal_state].all?(&:decision_mailed)).to eq false

      subject.sync_decided_appeals

      expect(decided_appeal_state.reload.decision_mailed).to eq true
      expect(undecided_appeal_state.reload.decision_mailed).to eq false
      expect(missing_vacols_case_appeal_state.reload.decision_mailed).to eq false

      clean_up_after_threads
    end

    it "catches standard errors", bypass_cleaner: true do
      expect([decided_appeal_state,
              undecided_appeal_state,
              missing_vacols_case_appeal_state].all?(&:decision_mailed)).to eq false

      error_text = "Fatal error in sync_decided_appeals_helper"
      allow(AppealState).to receive(:legacy).and_raise(StandardError.new(error_text))

      expect(Rails.logger).to receive(:error)

      expect { subject.sync_decided_appeals }.to raise_error(StandardError)

      clean_up_after_threads
    end

    # Clean up parallel threads
    # after(:each) { clean_up_after_threads }

    # VACOLS record's decision date will be set to simulate a decided appeal
    # decision_mailed will be set to false for the AppealState to verify the method
    # functionality
    def create_decided_appeal_state_with_case_record_and_hearing(decided_appeal, create_case)
      case_hearing = create(:case_hearing)
      decision_date = decided_appeal ? Time.current : nil
      vacols_case = create_case ? create(:case, case_hearings: [case_hearing], bfddec: decision_date) : nil
      appeal = create(:legacy_appeal, vacols_case: vacols_case)

      appeal.appeal_state.tap { _1.update!(decision_mailed: false) }
    end

    def clean_up_after_threads
      DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events])
    end
  end
end
