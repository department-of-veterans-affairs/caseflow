# frozen_string_literal: true

require "helpers/sync_attributes_with_bgs"

describe SyncAttributesWithBGS::VeteranCacheUpdater do
  describe "#run_by_file_number" do
    subject(:run_by_file_number) { described_class.new.run_by_file_number(file_number) }

    let(:file_number) { "dummy-file-number" }

    it "sets RequestStore current_user" do
      expect { run_by_file_number }.to change { RequestStore[:current_user] } .from(nil).to(User.system_user)
    end

    it "attempts to find veteran by file_number" do
      expect(Veteran).to receive(:find_by_file_number_or_ssn).with(file_number, sync_name: true)
      run_by_file_number
    end

    context "when veteran is not found" do
      before do
        allow(Veteran).to receive(:find_by).and_return(nil)
      end

      it "outputs error message" do
        expect { run_by_file_number }.to output("veteran was not found\n").to_stdout
      end
    end

    context "when veteran is found" do
      let(:file_number) { veteran.file_number }
      let(:veteran) { build(:veteran) }

      before do
        allow(Veteran).to receive(:find_by).and_return(veteran)
      end

      it "outputs success message" do
        expect { run_by_file_number }.to output(
          "Veteran Name: #{veteran.first_name} #{veteran.middle_name} #{veteran.last_name}\n"
        ).to_stdout
      end
    end
  end

  describe SyncAttributesWithBGS::PersonCacheUpdater do
    describe "#run_by_participant_id" do
      subject(:run_by_participant_id) { described_class.new.run_by_participant_id(participant_id) }
      let(:participant_id) { "12345678" }

      it "sets RequestStore current_user" do
        expect { run_by_participant_id }.to change { RequestStore[:current_user] } .from(nil).to(User.system_user)
      end

      it "attempts to find person by participant_id" do
        expect(Person).to receive(:find_by).with(participant_id: participant_id)
        run_by_participant_id
      end

      context "when person record is not found" do
        before { allow(Person).to receive(:find_by).and_return(nil) }

        it "outputs error message" do
          expect { subject }.to output("person was not found\n").to_stdout
        end
      end

      context "when person record is found" do
        let(:person) { instance_double("Person", first_name: "Billy", middle_name: "Bob", last_name: "Thornton") }

        before do
          allow(Person).to receive(:find_by).and_return(person)
        end

        context "when BGS request raises an error" do
          before do
            allow(person).to receive(:found?).and_raise(StandardError)
          end

          it "outputs error message" do
            expect { subject }.to output(
              "StandardError\n\nthere was bgs error. person not updated.\n"
            ).to_stdout
          end
        end

        context "when person bgs record is found" do
          let(:person_bgs_record) do
            {
              first_name: "BGS first_name",
              last_name: "BGS last_name",
              non_bgs_cached_attribute: "foobar"
            }
          end

          before do
            allow(person).to receive(:found?).and_return(true)
            allow(person).to receive(:bgs_record).and_return(person_bgs_record)
          end

          it "updates person record with bgs attributes" do
            allow(person).to receive(:previous_changes).and_return(first_name: %w[Peter Mark], updated_at: [])

            expect(person).to receive(:update!).with(
              first_name: "BGS first_name",
              last_name: "BGS last_name"
            )

            run_by_participant_id
          end

          context "when person update fails due to validation error" do
            before do
              allow(person).to receive(:update!).and_raise(ActiveModel::ValidationError.new(Person.new))
            end

            it "outputs error message" do
              expect { run_by_participant_id }.to output(
                "Validation failed: \n\nthere was an error. person not updated.\n"
              ).to_stdout
            end
          end

          context "when person update succeeds" do
            before { allow(person).to receive(:update!).and_return(true) }

            context "When person attributes did not change" do
              before { allow(person).to receive(:previous_changes).and_return({}) }

              it "outputs message" do
                expect { run_by_participant_id }.to output(
                  "person was not updated\n"
                ).to_stdout
              end
            end

            context "When person attributes changed" do
              before do
                allow(person).to receive(:previous_changes)
                  .and_return("first_name" => %w[Peter Mark], "updated_at" => [])
              end

              it "outputs success message" do
                expect { run_by_participant_id }.to output(
                  "Person Name: #{person.first_name} #{person.middle_name} #{person.last_name}\n"
                ).to_stdout
              end
            end
          end
        end
      end
    end
  end
end
