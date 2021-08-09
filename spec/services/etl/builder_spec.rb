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
  end

  describe "#last_built" do
    it "returns timestamp of last build" do
      # start first build with small delay so we don't bump up against
      # a rounding error on the fixtures created via "AMA Tableau SQL"
      first_build_time = Time.zone.now.round + 5.seconds
      ETL::Build.create(started_at: first_build_time)

      Timecop.travel(first_build_time) do
        # perform first full build
        builder = described_class.new
        expect(builder.last_built).to be_nil

        build = builder.full
        # use .to_s comparison since Rails.cache does not store .milliseconds
        expect(builder.last_built).to be_within(1.second).of(first_build_time)
        expect(build.built).to eq(95)
        expect(build.build_for("appeals").rows_inserted).to eq(14)

        last_build_time = builder.last_built
        hour_from_now = last_build_time + 1.hour

        # time travel forward and do an incremental build.
        # only one known thing (an appeal) should change.
        Timecop.travel(hour_from_now) do
          builder = described_class.new

          expect(builder.last_built).to eq(last_build_time)

          # "touch" a known appeal with known number of associations
          distributed_to_judge.touch

          build = builder.incremental

          expect(builder.last_built.to_s).to eq(hour_from_now.to_s)
          expect(build.built).to eq(1)
          expect(builder.built).to eq(build.built)
          expect(build.tables).to eq(["appeals"])
          expect(build.build_for("appeals").rows_inserted).to eq(0)
          expect(build.build_for("appeals").rows_updated).to eq(1)
        end
      end
    end

    it "updates aod_due_to_dob regardless of whether Appeal has been modified" do
      builder = described_class.new
      build = builder.full
      expect(build.built).to eq(95)
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
        Timecop.freeze(Time.zone.now.round) do
          described_class.syncer_klasses.each { |klass| expect(klass.target_class.all.count).to eq(0) }

          expect(ETL::Appeal.count).to eq(0)

          build = subject

          expect(build).to be_a(ETL::Build)
          expect(build).to be_complete
          expect(build.finished_at).to eq(Time.zone.now)
          expect(build.built).to eq(95)
          expect(build.tables).to include("appeals", "people", "tasks", "users", "organizations")
          expect(build.build_for("appeals").rows_inserted).to eq(14)
          expect(build.build_for("appeals").rows_updated).to eq(0)
          expect(build.build_for("users").rows_updated).to eq(0)
          expect(build.build_for("users").rows_inserted).to eq(25)

          expect(ETL::Task.count).to eq(34)
          expect(ETL::Appeal.count).to eq(14)
          expect(ETL::User.all.count).to eq(25)
          expect(ETL::Person.all.count).to eq(14)
          expect(ETL::OrganizationsUser.all.count).to eq(3)
          expect(ETL::Organization.all.count).to eq(5)
        end
      end
    end
  end

  describe "#incremental" do
    let(:last_build_time) { 2.days.ago.round } # shared example creates things 3 days old

    before do
      # create meta for "previous" run
      etl_build = ETL::Build.create(started_at: last_build_time)
      described_class.syncer_klasses.each do |syncer_klass|
        ETL::BuildTable.create(
          table_name: syncer_klass.target_class.table_name,
          started_at: last_build_time,
          etl_build: etl_build
        ).complete!
      end
      etl_build.complete!
    end

    subject { described_class.new(since: last_build_time).incremental }

    context "BVA status distribution" do
      it "syncs only records that have changed" do
        Timecop.freeze(Time.zone.now.round) do
          described_class.syncer_klasses.each { |klass| expect(klass.target_class.all.count).to eq(0) }

          build = subject

          expect(build).to be_a(ETL::Build)
          expect(build).to be_complete
          expect(build.finished_at).to eq(Time.zone.now)
          expect(build.built).to eq(92)
          expect(build.tables).to include("appeals", "people", "tasks", "users", "organizations")
          expect(build.build_for("appeals").rows_inserted).to eq(14)
          expect(build.build_for("appeals").rows_updated).to eq(0)
          expect(build.build_for("users").rows_inserted).to eq(24)
          expect(build.build_for("users").rows_rejected).to eq(0)

          expect(ETL::Task.count).to eq(34)
          expect(ETL::Appeal.count).to eq(14)
          expect(ETL::User.all.count).to eq(24)
          expect(ETL::Person.all.count).to eq(14)
          expect(ETL::OrganizationsUser.all.count).to eq(2)
          expect(ETL::Organization.all.count).to eq(4)
        end
      end
    end
  end

  describe "error handling" do
    before do
      allow(ETL::Appeal).to receive(:merge_original_attributes_to_target) { fail error }
    end

    subject { described_class.new }

    let(:error) { StandardError.new("oops!") }

    it "captures error string and sets status" do
      builder = subject

      expect { builder.full }.to raise_error(error)

      build = builder.build_record
      expect(build).to be_error
      expect(build.comments).to eq("oops!")
      expect(build.build_for("appeals")).to be_error
      expect(build.build_for("appeals").comments).to eq("oops!")
      expect(build.build_for("tasks")).to be_nil # we did not finish
    end
  end
end
