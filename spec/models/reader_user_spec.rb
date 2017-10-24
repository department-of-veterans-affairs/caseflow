require "rails_helper"

describe ReaderUser do
  context "when a reader user doesn't exist for a user with a reader role" do

    context "all_reader_users_without_details" do
      let(:users_with_reader_roles) {
        10.times.map do |i|
          Generators::User.create(roles: ["Reader"])
        end
      }
      before do
        10.times {
          # generate 10 other random users
          Generators::User.create(roles: ["NotReaderUser"])
        }
      end

      it "should return only users without associated reader_users" do
        users = ReaderUser.all_reader_users_without_details
        expect(users).to eq(users_with_reader_roles)
      end

      it "should only return 5 users if 5 is provided as a limit" do
        users = ReaderUser.all_reader_users_without_details(5)
        expect(users).to eq(users_with_reader_roles[0 .. 4])
      end
    end
  end
end
