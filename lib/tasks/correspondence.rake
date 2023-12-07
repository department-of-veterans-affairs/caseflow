# frozen_string_literal: true

namespace :correspondence do
  desc "setup data for intake correspondence (autotext and correspondence type)in UAT/PROD"
  task :setup_correspondence_data, [] => :environment do |_|
    STDOUT.puts("Creating data for Auto Text Tables")
    # creates intiial values for auto text table
    auto_texts_values = [
      "Address updated in VACOLS",
      "Decision sent to Senator or Congressman mm/dd/yy",
      "Interest noted in telephone call of mm/dd/yy",
      "Interest noted in evidence file regarding current appeal",
      "Email - responded via email on mm/dd/yy",
      "Email - written response req; confirmed receipt via email to Congress office on mm/dd/yy",
      "Possible motion pursuant to BVA decision dated mm/dd/yy",
      "Motion pursuant to BVA decision dated mm/dd/yy",
      "Statement in support of appeal by appellant",
      "Statement in support of appeal by rep",
      "Medical evidence X-Rays submitted or referred by",
      "Medical evidence clinical reports submitted or referred by",
      "Medical evidence examination reports submitted or referred by",
      "Medical evidence progress notes submitted or referred by",
      "Medical evidence physician's medical statement submitted or referred by",
      "C&P exam report",
      "Consent form (specify)",
      "Withdrawal of issues",
      "Response to BVA solicitation letter dated mm/dd/yy",
      "VAF 9 (specify)"
    ]

    auto_texts_values.each do |text|
      AutoText.find_or_create_by(name: text)
    end

    correspondence_types_list = [
      "Abeyance",
      "Attorney Inquiry",
      "CAVC Correspondence",
      "Change of address",
      "Congressional interest",
      "CUE related",
      "Death certificate",
      "Evidence or argument",
      "Extension request",
      "FOIA request",
      "Hearing Postponement Request",
      "Hearing related",
      "Hearing Withdrawal Request",
      "Advance on docket",
      "Motion for reconsideration",
      "Motion to vacate",
      "Other motions",
      "Power of attorney related",
      "Privacy Act complaints",
      "Privacy Act request",
      "Returned as undeliverable mail",
      "Status Inquiry",
      "Thurber",
      "Withdrawal of appeal"
    ]

    correspondence_types_list.each do |type|
      CorrespondenceType.find_or_create_by(name: type)
    end
  end

  desc "creates a 20 correspondence and correspondence_document for a veteran"
  task :create_correspondence, [:veteran_file_number] => :environment do |_, args|
    veteran = Veteran.find_by(file_number: args[:veteran_file_number].to_i)

    20.times do |package_doc_id|
      corres = ::Correspondence.create!(
        uuid: SecureRandom.uuid,
        portal_entry_date: Time.zone.now,
        source_type: "Mail",
        package_document_type_id: package_doc_id,
        correspondence_type_id: 4,
        cmp_queue_id: 1,
        cmp_packet_number: rand(2_000_000..2_999_999),
        va_date_of_receipt: Time.zone.yesterday,
        notes: "Notes from CMP - Multi Correspondence Seed",
        assigned_by_id: 81,
        veteran_id: veteran.id,
      )
      CorrespondenceDocument.find_or_create_by(
        document_file_number: veteran.file_number,
        uuid: SecureRandom.uuid,
        vbms_document_type_id: 1250,
        document_type: 1250,
        pages: 30,
        correspondence_id: corres.id
      )
    end
  end

  desc "create correspondence data in UAT given a veteran file number"
  task :create_correspondence_data, [] => :environment do |_|
    RequestStore[:current_user] = User.system_user

    STDOUT.puts("This script will create 20 new correspondence and
      correspondence_document for a veteran based off their file number")
    STDOUT.puts("Enter the veteran's file number")
    veteran_file_number = STDIN.gets.chomp

    if veteran_file_number.to_i.is_a? Integer
      STDOUT.puts("Creating correspondences")
      Rake.application.invoke_task("correspondence:create_correspondence[#{veteran_file_number}]")
      Rake::Task["correspondence:create_correspondence"].reenable
      STDOUT.puts("Correspondences created!")
    else
      STDOUT.puts("Improper input...")
    end
  end

  desc "creates 10 appeals for a vetean: 5 with evidence submission tasks and 5 without"
  task :create_test_appeals, [] => :environment do |_|
    RequestStore[:current_user] = User.system_user

    STDOUT.puts("This script will create 5 evidence appeals and 5 direct review appeals for a veteran.")
    STDOUT.puts("Enter the veteran's file number")
    veteran_file_number = STDIN.gets.chomp

    if veteran_file_number.to_i.is_a? Integer
      veteran = Veteran.find_by(file_number: veteran_file_number.to_i)
      # evidence appeals
      5.times do
        appeal = Appeal.create!(
          veteran_file_number: veteran.file_number,
          receipt_date: Time.zone.now,
          established_at: Time.zone.now,
          docket_type: Constants.AMA_DOCKETS.evidence_submission
        )
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      end

      # direct review appeals.
      5.times do
        appeal = Appeal.create!(
          veteran_file_number: veteran.file_number,
          receipt_date: Time.zone.now,
          established_at: Time.zone.now,
          docket_type: Constants.AMA_DOCKETS.direct_review
        )
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      end
    else
      STDOUT.puts("Improper input...")
    end
  end
end
