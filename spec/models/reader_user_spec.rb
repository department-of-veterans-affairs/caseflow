# frozen_string_literal: true

require "rails_helper"

describe ReaderUser do
  context "when a reader users do not exist for a user with a reader role" do
    let!(:users_with_reader_roles) do
      Array.new(10) do
        Generators::User.create(roles: ["Reader"])
      end
    end

    before(:each) do
      10.times do
        # generate 10 other random users
        Generators::User.create(roles: ["NotReaderUser"])
      end
    end

    context "all_without_records" do
      it "should return only users without associated reader_users" do
        users = ReaderUser.all_without_records
        expect(users).to eq(users_with_reader_roles)
      end

      it "should only return 5 users if 5 is provided as a limit" do
        users = ReaderUser.all_without_records(5)
        expect(users).to eq(users_with_reader_roles[0..4])
      end
    end

    context "all_by_documents_fetched_at" do
      it "should return reader_users sorted by fetched_at" do
        ReaderUser.all_by_documents_fetched_at.each_with_index do |reader_user, i|
          expect(reader_user.user.id).to eq(users_with_reader_roles[i].id)
        end
      end

      context "when reader_users have been fetched at within 24 hours" do
        before do
          # at this point, we've generated users with the reader role
          # now also create reader_user records
          ReaderUser.create_records
          ReaderUser.first.update!(documents_fetched_at: 25.hours.ago)
          ReaderUser.second.update!(documents_fetched_at: 2.hours.ago)
          ReaderUser.third.update!(documents_fetched_at: 2.hours.ago)
        end

        it "should return only readers who fetched documents over 24 hours ago" do
          ReaderUser.all_by_documents_fetched_at.each do |reader_user|
            expect(reader_user.documents_fetched_at).to eq(nil).or be < 24.hours.ago
          end
        end
      end
    end
  end
end
