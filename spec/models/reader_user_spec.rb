require "rails_helper"

describe ReaderUser do
  context "when a reader users do not exist for a user with a reader role" do
    before(:each) do
      10.times do
        # generate 10 other random users
        Generators::User.create(roles: ["NotReaderUser"])
      end

      @users_with_reader_roles = 10.times.map do |_i|
        Generators::User.create(roles: ["Reader"])
      end
    end

    context "all_reader_users_without_details" do
      it "should return only users without associated reader_users" do
        users = ReaderUser.all_reader_users_without_details
        expect(users).to eq(@users_with_reader_roles)
      end

      it "should only return 5 users if 5 is provided as a limit" do
        users = ReaderUser.all_reader_users_without_details(5)
        expect(users).to eq(@users_with_reader_roles[0..4])
      end
    end

    context "all_by_documents_fetched_at" do
      it "should return reader_users sorted by fetched_at" do
        ReaderUser.all_by_documents_fetched_at.each_with_index do |reader_user, i|
          expect(reader_user.user.id).to eq(@users_with_reader_roles[i].id)
        end
      end
    end
  end
end
