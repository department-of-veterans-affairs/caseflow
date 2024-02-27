# frozen_string_literal: true

require Rails.root.join("db/migrate/20240226140103_add_hearing_id_and_hearing_type_to_conference_links.rb")

def column(column_name)
  ConferenceLink.columns.find { |col| col.name == column_name }
end

describe AddHearingIdAndHearingTypeToConferenceLinks do
  let(:migration_paths) { Rails.root.join("db/migrate") }
  let(:test_version) { 20240226140103 }
  let(:previous_version) { 20240130191529 }
  let(:conference_link) { create(:webex_conference_link) }

  describe "up" do
    before :each do
      ActiveRecord::MigrationContext.new(migration_paths).migrate(previous_version)
      ConferenceLink.reset_column_information
    end

    subject do
      ActiveRecord::MigrationContext.new(migration_paths).migrate(test_version)
      ConferenceLink.reset_column_information
    end

    it "adds two new columns to conference_links table" do
      expect { subject }.to change { ConferenceLink.columns.count }.by 2
    end

    it "adds hearing_id column of type bigint to conference_links table" do
      expect { subject }.to change { column("hearing_id").present? }.from(false).to(true)
      expect(column("hearing_id").sql_type).to eq("bigint")
    end

    it "adds hearing_type column of type string (character varying) to conference_links table" do
      expect { subject }.to change { column("hearing_type").present? }.from(false).to(true)
      expect(column("hearing_type").sql_type).to eq("character varying")
    end

    it "updates hearing_day_id column to be nullable" do
      expect { subject }.to change { column("hearing_day_id").null }.from(false).to(true)
      expect(conference_link.hearing_day).to be_nil
      expect(conference_link.valid?).to be true
    end
  end

  describe "down" do
    before :each do
      ActiveRecord::MigrationContext.new(migration_paths).migrate(test_version)
      ConferenceLink.reset_column_information
    end

    subject do
      ActiveRecord::MigrationContext.new(migration_paths).migrate(previous_version)
      ConferenceLink.reset_column_information
    end

    it "removes two new columns from conference_links table" do
      expect { subject }.to change { ConferenceLink.columns.count }.by(-2)
    end

    it "removes hearing_id column from conference_links table" do
      expect { subject }.to change { column("hearing_id").present? }.from(true).to(false)
    end

    it "removes hearing_type column from conference_links table" do
      expect { subject }.to change { column("hearing_type").present? }.from(true).to(false)
    end

    it "reverts hearing_day_id column to be non-nullable" do
      expect { subject }.to change { column("hearing_day_id").null }.from(true).to(false)
      expect { conference_link }.to raise_error do |error|
        expect(error.class).to be(ActiveRecord::NotNullViolation)
        expect(error.message).to include(
          "null value in column \"hearing_day_id\" of relation \"conference_links\" violates not-null constraint"
        )
      end
    end
  end
end
