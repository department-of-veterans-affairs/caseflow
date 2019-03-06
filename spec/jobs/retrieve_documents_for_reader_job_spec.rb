# frozen_string_literal: true

require "rails_helper"
require "faker"

describe RetrieveDocumentsForReaderJob do
  context ".perform" do
    context "A user exists with reader privileges" do
      let!(:user_with_reader_role) do
        Generators::User.create(roles: ["Reader"])
      end

      let!(:user_without_reader_role) do
        Generators::User.create(roles: ["Something else"])
      end

      context "without a reader_user" do
        it "should create a reader_user and run FindDocumentsForReaderUserJob for this user" do
          expect(FetchDocumentsForReaderUserJob).to receive(:perform_later).once do |reader_user|
            expect(reader_user.user.id).to eq(user_with_reader_role.id)
          end
          RetrieveDocumentsForReaderJob.perform_now
        end
      end

      context "with existing reader_user" do
        before do
          Generators::ReaderUser.create(user_id: user_with_reader_role.id)
        end

        it "should FindDocumentsForReaderUserJob for this user" do
          expect(FetchDocumentsForReaderUserJob).to receive(:perform_later).once do |reader_user|
            expect(reader_user.user.id).to eq(user_with_reader_role.id)
          end
          RetrieveDocumentsForReaderJob.perform_now
        end
      end

      context "with a limit parameter of 5 passed in" do
        before do
          # create 10 users
          10.times do
            u = Generators::User.create(roles: ["Reader"])
            Generators::ReaderUser.create(user_id: u.id)
          end
        end
        it "should only run FetchDocumentsForReaderUserJob 5 times" do
          expect(FetchDocumentsForReaderUserJob).to receive(:perform_later).with(anything).exactly(5).times
          RetrieveDocumentsForReaderJob.perform_now("limit" => 5)
        end
      end
    end
  end
end
