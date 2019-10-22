# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe UserFinder, :all_dbs do
  let!(:judge) do
    create(:user).tap do |judge|
      create(:staff, :judge_role, sdomainid: judge.css_id)
    end
  end
  let!(:user) { create(:user, css_id: "foobar") }
  let(:css_id) {}
  let(:role) {}
  let(:organization) {}

  describe "#users" do
    subject { described_class.new(css_id: css_id, role: role, organization: organization).users.to_a }

    context "css_id" do
      let(:css_id) { judge.css_id[0..2] } # first 3 characters

      it "finds by fuzzy css_id" do
        expect(subject).to eq([judge])
      end
    end

    context "role" do
      let(:role) { "Judge" }

      it "finds by role" do
        expect(subject).to eq([judge])
      end
    end

    context "organization" do
      let(:organization) { create(:organization).tap { |org| org.users << judge } }

      it "finds by organization" do
        expect(subject).to eq([judge])
      end
    end

    context "multiple params" do
      let(:css_id) { "foobar" }
      let(:role) { "Judge" }

      it "computes intersection" do
        expect(subject).to eq([])
      end
    end
  end
end
