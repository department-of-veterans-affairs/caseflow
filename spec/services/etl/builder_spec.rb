# frozen_string_literal: true

describe ETL::Builder, :etl, :all_dbs do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  let!(:vacols_user1) { create(:staff, :judge_role) }
  let!(:vacols_user2) { create(:staff, :attorney_judge_role) }
  let!(:user1) { create(:user, css_id: vacols_user1.sdomainid) }
  let!(:user2) { create(:user, css_id: vacols_user2.sdomainid, updated_at: 3.days.ago.round) }
  let!(:user3) { create(:user) }
  let!(:org1) { create(:organization, updated_at: 3.days.ago.round) }
  let!(:org2) { create(:organization) }
  let!(:org_user1) { create(:organizations_user, user: user, organization: org1) }
  let!(:org_user2) { create(:organizations_user, user: user, organization: org2, updated_at: 3.days.ago.round) }
  let(:user) { create(:user) }

  before do
    Timecop.travel(3.days.ago.round) do
      CachedUser.sync_from_vacols
    end

    Timecop.freeze(Time.zone.now)
  end

  describe "#last_built" do
    it "returns timestamp of last build" do
      Timecop.freeze(Time.zone.now) do
        builder = described_class.new
        build = builder.full

        # use .to_s comparison since Rails.cache does not store .milliseconds
        expect(builder.last_built.to_s).to eq(Time.zone.now.to_s)
        expect(build.built).to eq(88)
      end

      hour_from_now = Time.zone.now + 1.hour

      Timecop.freeze(hour_from_now) do
        builder = described_class.new

        expect(builder.last_built).to eq((Time.zone.now - 1.hour).to_s)

        Appeal.last.touch # at least one thing changed

        build = builder.incremental

        expect(builder.last_built.to_s).to eq(hour_from_now.to_s)
        expect(build.built).to be > 0
        expect(builder.built).to eq(build.built)
      end
    end

    it "updates aod_due_to_dob regardless of whether Appeal has been modified" do
      builder = described_class.new
      build = builder.full
      expect(build.built).to eq(88)
      expect(ETL::Appeal.where(aod_due_to_dob: true).count).to eq(1)

      # change dob for one active
      ETL::Appeal.active.where(aod_due_to_dob: false)
        .where("claimant_dob > ?", 76.years.ago.round).first
        .update(claimant_dob: 76.years.ago.round)

      # and for one inactive
      ETL::Appeal.where(aod_due_to_dob: false)
        .where(active_appeal: false)
        .where("claimant_dob > ?", 76.years.ago.round).first
        .update(claimant_dob: 76.years.ago.round)

      builder = described_class.new(since: Time.zone.now + 1.day)
      build = builder.incremental
      expect(build.built).to eq(0)
      expect(ETL::Appeal.where(aod_due_to_dob: true).count).to eq(2) # skips inactive
    end
  end

  describe "#full" do
    subject { described_class.new.full }

    context "BVA status distribution" do
      it "syncs all records" do
        described_class::ETL_KLASSES.each { |klass| expect("ETL::#{klass}".constantize.all.count).to eq(0) }

        build = subject

        expect(build.built).to eq(88)
        expect(ETL::Task.count).to eq(31)
        expect(ETL::Appeal.count).to eq(13)
        expect(ETL::User.all.count).to eq(23)
        expect(ETL::Person.all.count).to eq(13)
        expect(ETL::OrganizationsUser.all.count).to eq(3)
        expect(ETL::Organization.all.count).to eq(5)
      end
    end
  end

  describe "#incremental" do
    subject { described_class.new(since: 2.days.ago.round).incremental }

    context "BVA status distribution" do
      it "syncs only records that have changed" do
        described_class::ETL_KLASSES.each { |klass| expect("ETL::#{klass}".constantize.all.count).to eq(0) }

        build = subject

        expect(build.built).to eq(85)
        expect(ETL::Task.count).to eq(31)
        expect(ETL::Appeal.count).to eq(13)
        expect(ETL::User.all.count).to eq(22)
        expect(ETL::Person.all.count).to eq(13)
        expect(ETL::OrganizationsUser.all.count).to eq(2)
        expect(ETL::Organization.all.count).to eq(4)
      end
    end
  end
end
