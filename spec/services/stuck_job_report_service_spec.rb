# frozen_string_literal: true

describe StuckJobReportService, :postres do
  ERROR_TEXT = "Descriptive Error Name"
  FAILED_TRANSACTION_ERROR = "great error"
  STUCK_JOB_NAME = "VBMS::UnknownUser"

  before do
    Timecop.freeze
  end

  fake_data = [
    {
      class_name: "Decision Document",
      id: 1
    },
    {
      class_name: "Decision Document",
      id: 2
    },
    {
      class_name: "Decision Document",
      id: 3
    },
    {
      class_name: "Decision Document",
      id: 4
    }
  ]

  subject { described_class.new }

  context "StuckJobReportService" do
    it "writes the job report" do
      subject.append_record_count(4, STUCK_JOB_NAME)

      fake_data.map do |data|
        subject.append_single_record(data[:class_name], data[:id])
      end

      subject.append_record_count(0, STUCK_JOB_NAME)
      subject.write_log_report(ERROR_TEXT)

      expect(subject.logs[0]).to include("#{Time.zone.now} ********** Remediation Log Report **********")
      expect(subject.logs[1]).to include("#{STUCK_JOB_NAME}::Log - Total number of Records with Errors: 4")
      expect(subject.logs[5]).to include("Record Type: Decision Document - Record ID: 4.")
      expect(subject.logs[6]).to include("#{STUCK_JOB_NAME}::Log - Total number of Records with Errors: 0")
    end

    it "writes error log report" do
      subject.append_record_count(4, STUCK_JOB_NAME)

      fake_data.map do |data|
        subject.append_error(data[:class_name], data[:id], FAILED_TRANSACTION_ERROR)
      end

      subject.append_record_count(4, STUCK_JOB_NAME)
      subject.write_log_report(ERROR_TEXT)

      expect(subject.logs[0]).to include("#{Time.zone.now} ********** Remediation Log Report **********")
      expect(subject.logs[1]).to include("#{STUCK_JOB_NAME}::Log - Total number of Records with Errors: 4")
      expect(subject.logs[5]).to include("Record Type: Decision Document - Record ID: 4. Encountered great error, record not updated.")
      expect(subject.logs[6]).to include("#{STUCK_JOB_NAME}::Log - Total number of Records with Errors: 4")
    end
  end
end
