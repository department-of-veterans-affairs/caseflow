# frozen_string_literal: true

require "rails_helper"

describe "data_migrations" do
  include_context "rake"

  describe "data_migrations:migrate_virtual_hearings_veteran_email_and_veteran_email_sent" do
    let(:args) { [] }

    let(:count) { 20 }
    let!(:virtual_hearings) do
      count.times do
        create(:virtual_hearing, hearing: create(:hearing, regional_office: "RO06"))
      end
    end

    subject do
      Rake::Task["data_migrations:migrate_virtual_hearings_veteran_email_and_veteran_email_sent"].reenable
      Rake::Task["data_migrations:migrate_virtual_hearings_veteran_email_and_veteran_email_sent"].invoke(*args)
    end

    before do
      VirtualHearing.all.each do |vh|
        vh.update!(veteran_email: "fake@email.com", veteran_email_sent: true)
      end
    end

    context "dry run" do
      it "only describes what changes will be made" do
        description = []
        VirtualHearing.all.each do |virtual_hearing|
          veteran_email = virtual_hearing.veteran_email
          veteran_email_sent = virtual_hearing.veteran_email_sent
          description << "Would migrate (veteran_email: #{veteran_email}) to appellant_email and " \
            "(veteran_email_sent: #{veteran_email_sent}) to appellant_email_sent " \
            "for virtual_hearing (#{virtual_hearing.id})"
        end

        expected_output = <<~OUTPUT
          *** DRY RUN
          *** pass 'false' as the first argument to execute
          Would migrate veteran_email and veteran_email_sent data for #{count} VirtualHearing objects
          #{description.join("\n")}
        OUTPUT

        expect(Rails.logger).to receive(:info).with("Invoked with: ")
        expect(Rails.logger).to receive(:info).with("Starting dry run")
        description.each { |line| expect(Rails.logger).to receive(:info).with(line) }
        expect { subject }.to output(expected_output).to_stdout
      end
    end

    context "perform migration" do
      let(:args) { ["false"] }

      it "makes changes and describes them" do
        description = []
        VirtualHearing.all.each do |virtual_hearing|
          veteran_email = virtual_hearing.veteran_email
          veteran_email_sent = virtual_hearing.veteran_email_sent
          description << "Migrating (veteran_email: #{veteran_email}) to appellant_email and " \
            "(veteran_email_sent: #{veteran_email_sent}) to appellant_email_sent " \
            "for virtual_hearing (#{virtual_hearing.id})"
        end

        expected_output = <<~OUTPUT
          Migrating veteran_email and veteran_email_sent data for #{count} VirtualHearing objects
          #{description.join("\n")}
        OUTPUT

        expect(Rails.logger).to receive(:info).with("Invoked with: false")
        expect(Rails.logger).to receive(:info).with("Starting migration")
        description.each { |line| expect(Rails.logger).to receive(:info).with(line) }
        expect { subject }.to output(expected_output).to_stdout

        # check that fields were migrated correctly
        VirtualHearing.all.each do |vh|
          expect(vh.appellant_email).to eq("fake@email.com")
          expect(vh.appellant_email_sent).to eq(true)
        end
      end
    end
  end
end
