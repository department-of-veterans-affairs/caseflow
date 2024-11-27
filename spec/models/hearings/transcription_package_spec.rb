# frozen_string_literal: true

require "rails_helper"

RSpec.describe TranscriptionPackage, type: :model do
  let!(:h_1) { create(:hearing) }
  let!(:lh_1) { create(:legacy_hearing) }

  let!(:c_1) { create(:transcription_contractor, name: "Contractor One") }
  let!(:c_2) { create(:transcription_contractor, name: "Contractor Two") }
  let!(:c_3) { create(:transcription_contractor, name: "Contractor Three") }

  let!(:t_1) { create(:transcription, task_number: "BVA2024001") }
  let!(:t_2) { create(:transcription, task_number: "BVA2024002") }
  let!(:t_3) { create(:transcription, task_number: "BVA2024003") }
  let!(:t_4) { create(:transcription, task_number: "BVA2024004") }

  let!(:tf_1) { create(:transcription_file, transcription: t_1) }
  let!(:tf_2) { create(:transcription_file, transcription: t_2) }
  let!(:tf_3) { create(:transcription_file, transcription: t_3) }
  let!(:tf_4) { create(:transcription_file, transcription: t_4) }

  let!(:transcription_package_1) do
    create(
      :transcription_package,
      task_number: "BVA2024001",
      contractor: c_1,
      created_at: "2024-09-01 00:00:00",
      expected_return_date: "2024-09-15",
      legacy_hearings: [lh_1],
      hearings: [h_1]
    )
  end

  let!(:transcription_package_2) do
    create(
      :transcription_package,
      task_number: "BVA2024002",
      contractor: c_2,
      created_at: "2024-09-02 00:00:00",
      expected_return_date: "2024-09-16"
    )
  end

  let!(:transcription_package_3) do
    create(
      :transcription_package,
      task_number: "BVA2024003",
      contractor: c_3,
      created_at: "2024-09-03 00:00:00",
      expected_return_date: "2024-09-17"
    )
  end

  let!(:transcription_package_4) do
    create(
      :transcription_package,
      task_number: "BVA2024004",
      contractor: c_1,
      created_at: "2024-09-04 00:00:00",
      expected_return_date: "2024-09-18"
    )
  end

  it "can filter between two dates" do
    transcription_packages = TranscriptionPackage.filter_by_date(
      %w(between 2024-09-03 2024-09-04),
      "created_at"
    )
    expect(transcription_packages).to eq([transcription_package_3, transcription_package_4])
  end

  it "can filter after a date" do
    transcription_packages = TranscriptionPackage.filter_by_date(
      %w(after 2024-09-03),
      "created_at"
    )
    expect(transcription_packages).to eq([transcription_package_4])
  end

  it "can filter before a date" do
    transcription_packages = TranscriptionPackage.filter_by_date(
      %w(before 2024-09-03),
      "created_at"
    )
    expect(transcription_packages).to eq([transcription_package_1, transcription_package_2])
  end

  it "can filter on a date" do
    transcription_packages = TranscriptionPackage.filter_by_date(
      %w(on 2024-09-03),
      "created_at"
    )
    expect(transcription_packages).to eq([transcription_package_3])
  end

  it "can filter by contractor" do
    transcription_packages = TranscriptionPackage.joins(:contractor).filter_by_contractor("Contractor Two")
    expect(transcription_packages).to eq([transcription_package_2])
  end

  it "can filter by search on work order" do
    transcription_packages = TranscriptionPackage.search("BVA2024003")
    expect(transcription_packages).to eq(
      [transcription_package_3]
    )
  end

  it "can handle missing search records" do
    transcription_packages = TranscriptionPackage.search("BVA39293499")
    expect(transcription_packages).to eq(
      []
    )
  end

  it "can order by field" do
    transcription_packages = TranscriptionPackage.joins(:contractor)
      .order_by_field("asc", "transcription_contractors.name")
    expect(transcription_packages).to eq(
      [transcription_package_1, transcription_package_4, transcription_package_3, transcription_package_2]
    )
  end

  it "can display a contractor name" do
    transcription_package = TranscriptionPackage.first
    expect(transcription_package.contractor_name).to eq("Contractor One")
  end

  it "can display all hearings serialized" do
    transcription_package = TranscriptionPackage.first
    expect(transcription_package.all_hearings).to eq(
      [
        {
          caseDetails: h_1.appeal.appellant_or_veteran_name + " (" + h_1.appeal.veteran_file_number + ")",
          docketNumber: h_1.docket_number,
          hearingType: "Hearing",
          appealId: h_1.appeal.external_id
        },
        {
          caseDetails: lh_1.appeal.appellant_or_veteran_name + " (" + lh_1.appeal.veteran_file_number + ")",
          docketNumber: lh_1.docket_number,
          hearingType: "LegacyHearing",
          appealId: lh_1.appeal.external_id
        }
      ]
    )
  end

  it "can format the upload box date" do
    transcription_package = TranscriptionPackage.new(date_upload_box: "2024-09-01")
    expect(transcription_package.formatted_date_upload_box).to eq("9/1/2024")
  end

  it "can format he returned at date" do
    transcription_package = TranscriptionPackage.new(returned_at: "2024-09-01")
    expect(transcription_package.formatted_returned_at).to eq("9/1/2024")
  end

  it "can count the contents" do
    transcription_package = TranscriptionPackage.first
    expect(transcription_package.contents_count).to eq(2)

    transcription_package = TranscriptionPackage.last
    expect(transcription_package.contents_count).to eq(0)
  end

  describe "#next_task_number" do
    let!(:transcription_package_1) do
      create(
        :transcription_package,
        task_number: "BVA-2026-0091",
        contractor: c_1,
        created_at: "2024-09-01 00:00:00",
        expected_return_date: "2024-09-15",
        legacy_hearings: [lh_1],
        hearings: [h_1]
      )
    end

    let!(:transcription_package_2) do
      create(
        :transcription_package,
        task_number: "BVA-2026-0001",
        contractor: c_1,
        created_at: "2024-09-01 00:00:00",
        expected_return_date: "2024-09-15",
        legacy_hearings: [lh_1],
        hearings: [h_1]
      )
    end

    it "defaults to 1 if no package from the fiscal year is found" do
      Timecop.freeze(Time.utc(2026, 10, 1, 12, 0, 0))
      expect(TranscriptionPackage.next_task_number).to eq("BVA-2027-0001")
    end

    it "increments by one more than the newest package for a year" do
      Timecop.freeze(Time.utc(2026, 9, 30, 12, 0, 0))
      expect(TranscriptionPackage.next_task_number).to eq("BVA-2026-0092")
    end
  end
end
