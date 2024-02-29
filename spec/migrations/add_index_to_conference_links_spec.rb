# frozen_string_literal: true

require Rails.root.join("db/migrate/20240226201012_add_index_to_conference_links.rb")

def hearing_index
  ActiveRecord::Base.connection.indexes("conference_links").find do |idx|
    idx.name == "index_conference_links_on_hearing_id_and_hearing_type"
  end
end

describe AddIndexToConferenceLinks do
  let(:migration_paths) { Rails.root.join("db/migrate") }
  let(:test_version) { 20240226201012 }
  let(:previous_version) { 20240226140103 }

  before :each do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe "up" do
    before :each do
      ActiveRecord::MigrationContext.new(migration_paths).migrate(previous_version)
      ConferenceLink.reset_column_information
    end

    subject do
      ActiveRecord::MigrationContext.new(migration_paths).migrate(test_version)
      ConferenceLink.reset_column_information
    end

    it "adds index on hearing_id and hearing_type to conference_links table" do
      expect { subject }.to change { hearing_index.present? }.from(false).to(true)
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

    it "adds index on hearing_id and hearing_type to conference_links table" do
      expect { subject }.to change { hearing_index.present? }.from(true).to(false)
    end
  end
end
