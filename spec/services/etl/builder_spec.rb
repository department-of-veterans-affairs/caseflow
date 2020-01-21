# frozen_string_literal: true

describe ETL::Builder, :etl, :all_dbs do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  let!(:vacols_user1) { create(:staff, :judge_role) }
  let!(:vacols_user2) { create(:staff, :attorney_judge_role) }
  let!(:user1) { create(:user, css_id: vacols_user1.sdomainid) }
  let!(:user2) { create(:user, css_id: vacols_user2.sdomainid, updated_at: 3.days.ago) }
  let!(:user3) { create(:user) }
  let!(:org1) { create(:organization, updated_at: 3.days.ago) }
  let!(:org2) { create(:organization) }
  let!(:org_user1) { create(:organizations_user, user: user, organization: org1) }
  let!(:org_user2) { create(:organizations_user, user: user, organization: org2, updated_at: 3.days.ago) }
  let(:user) { create(:user) }

  before do
    Timecop.travel(3.days.ago) do
      CachedUser.sync_from_vacols
    end

    Timecop.freeze(Time.zone.now)
  end

  describe "#last_built" do
    it "returns timestamp of last build" do
      Timecop.freeze(Time.zone.now) do
        builder = described_class.new
        built = builder.full

        # use .to_s comparison since Rails.cache does not store .milliseconds
        expect(builder.last_built.to_s).to eq(Time.zone.now.to_s)
        expect(built).to eq(75)
      end

      hour_from_now = Time.zone.now + 1.hour

      Timecop.freeze(hour_from_now) do
        builder = described_class.new

        expect(builder.last_built).to eq((Time.zone.now - 1.hour).to_s)

        Appeal.last.touch # at least one thing changed

        built = builder.incremental

        expect(builder.last_built.to_s).to eq(hour_from_now.to_s)
        expect(built).to be > 0
      end
    end
  end

  describe "#full" do
    subject { described_class.new.full }

    context "BVA status distribution" do
      it "syncs all records" do
        described_class::ETL_KLASSES.each { |klass| expect("ETL::#{klass}".constantize.all.count).to eq(0) }

        built = subject

        expect(built).to eq(75)
        expect(ETL::Task.count).to eq(31)
        expect(ETL::Appeal.count).to eq(13)
        expect(ETL::User.all.count).to eq(23)
        expect(ETL::OrganizationsUser.all.count).to eq(3)
        expect(ETL::Organization.all.count).to eq(5)
      end
    end
  end

  describe "#incremental" do
    subject { described_class.new(since: 2.days.ago).incremental }

    context "BVA status distribution" do
      it "syncs only records that have changed" do
        described_class::ETL_KLASSES.each { |klass| expect("ETL::#{klass}".constantize.all.count).to eq(0) }

        built = subject

        expect(built).to eq(72)
        expect(ETL::Task.count).to eq(31)
        expect(ETL::Appeal.count).to eq(13)
        expect(ETL::User.all.count).to eq(22)
        expect(ETL::OrganizationsUser.all.count).to eq(2)
        expect(ETL::Organization.all.count).to eq(4)
      end
    end
  end
end
