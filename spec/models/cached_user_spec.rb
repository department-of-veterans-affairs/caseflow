# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe CachedUser, :all_dbs do
  describe ".sync_from_vacols" do
    context "5 VACOLS staff exist" do
      before do
        5.times { create(:staff) }
      end

      it "copies relevant attributes" do
        expect(CachedUser.count).to eq(0)

        described_class.sync_from_vacols

        expect(CachedUser.count).to eq(5)
      end
    end

    context "VACOLS staff attributes change" do
      before do
        5.times { create(:staff) }
      end

      it "updates local cache" do
        described_class.sync_from_vacols

        staff = VACOLS::Staff.first
        cached_user = described_class.find_by(sdomainid: staff.sdomainid)

        staff.stafkey = "foobar"
        staff.save!

        described_class.sync_from_vacols

        expect(cached_user.reload.stafkey).to eq("foobar")
      end
    end

    context "Staff missing sdomainid value" do
      before do
        create(:staff, sdomainid: nil)
      end

      it "skips staff record" do
        described_class.sync_from_vacols

        expect(CachedUser.count).to eq(0)
      end
    end
  end
end
