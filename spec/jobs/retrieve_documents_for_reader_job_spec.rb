# frozen_string_literal: true

require "rails_helper"
require "faker"

describe RetrieveDocumentsForReaderJob do
  context ".perform" do
    context "a user exists who have been recently active" do
      let!(:active_user) do
        create(:user, last_login_at: 3.days.ago )
      end

      let!(:inactive_user) do
        create(:user, last_login_at: 3.months.ago )
      end

      context "without a reader user" do
        it "should create a reader user and run FindDocumentsForReaderUserJob for this user" do
          expect(FetchDocumentsForReaderUserJob).to receive(:perform_later).once do |reader_user|
            expect(reader_user.user.id).to eq(active_user.id)
          end
          RetrieveDocumentsForReaderJob.perform_now
        end
      end

      context "with existing active reader user" do
        before do
          Generators::ReaderUser.create(user_id: active_user.id)
        end

        it "should run FindDocumentsForReaderUserJob for this user" do
          expect(FetchDocumentsForReaderUserJob).to receive(:perform_later).once do |reader_user|
            expect(reader_user.user.id).to eq(active_user.id)
          end
          RetrieveDocumentsForReaderJob.perform_now
        end
      end

      context "with existing inactive reader user" do
        before do
          Generators::ReaderUser.create(user_id: inactive_user.id)
        end

        it "should only run FindDocumentsForReaderUserJob for the active user" do
          expect(FetchDocumentsForReaderUserJob).to receive(:perform_later).once do |reader_user|
            expect(reader_user.user.id).to eq(active_user.id)
          end
          RetrieveDocumentsForReaderJob.perform_now
        end
      end
    end
  end
end
