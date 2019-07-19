# frozen_string_literal: true

require "rails_helper"

describe UpdateCachedAppealsAttributesJob do
  let!(:vacols_folder1) {
    VACOLS::Folder.create(ticknum: "1")
  }
  let!(:vacols_folder2) {
    VACOLS::Folder.create(ticknum: "2")
  }

  let!(:legacy_appeal1) { LegacyAppeal.create(vacols_id: "1") }
  let!(:appeal2) { LegacyAppeal.create(vacols_id: "2") }

  context "When there are open legacy and AMA appeals, the cache" do

    it "creates cached appeals for all appeals associated with open tasks" do
    end

    if "associates the correct docket_number with the correct vacols_id" do
    end

    it "creates the proper docket numbers for AMA appeals" do
    end

    it "creates the correct number of cached appeals" do
    end

    it "does not create more than 1 cached appeal for each appeal" do
    end

    it "caches the docket_types correctly" do
    end

    it "fails gracefully" do
    end 


  end


end
