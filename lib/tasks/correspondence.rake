# frozen_string_literal: true

require_relative "../../db/seeds/base"
require_relative "../../db/seeds/correspondence"
require_relative "../../db/seeds/vbms_document_types"
require_relative "../../db/seeds/correspondence_types"
require_relative "../../db/seeds/package_document_types"
require_relative "../../db/seeds/multi_correspondences"

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

  task :correspondences_with_multiple_documents, [] => :environment do |_|
    @file_number ||= 500_000_000
    @participant_id ||= 850_000_000
    while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1))
      @file_number += 100
      @participant_id += 100
    end

    @cmp_packet_number ||= 1_000_000_000
    @cmp_packet_number += 10_000 while ::Correspondence.find_by(cmp_packet_number: @cmp_packet_number + 1)
    create_correspondences_with_documents
  end

  task :vbms_document_types, [] => :environment do |_|
    create_document_types
  end

  task :correspondence_types, [] => :environment do |_|
    create_correspondence_types
  end

  task :package_document_types, [] => :environment do |_|
    create_package_document_types
  end

  task :multi_correspondences, [] => :environment do |_|
    @file_number ||= 550_000_000
    @participant_id ||= 650_000_000
    while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1))
      @file_number += 100
      @participant_id += 100
    end

    @cmp_packet_number ||= 2_000_000_000
    @cmp_packet_number += 10_000 while ::Correspondence.find_by(cmp_packet_number: @cmp_packet_number + 1)
    RequestStore[:current_user] = User.find_by_css_id("BVADWISE")
    create_multi_correspondences
  end

  desc "creates a 20 correspondence and correspondence_document for a veteran"
  task :create_correspondence, [:veteran_file_number] => :environment do |_, args|
    veteran = Veteran.find_by(file_number: args[:veteran_file_number].to_i)

    (1..20).each do |package_doc_id|
      corres = ::Correspondence.create!(
        uuid: SecureRandom.uuid,
        portal_entry_date: Time.zone.now,
        source_type: "Mail",
        package_document_type_id: package_doc_id,
        correspondence_type_id: 4,
        cmp_queue_id: 1,
        cmp_packet_number: rand(2_000_000..2_999_999),
        va_date_of_receipt: Faker::Date.between(from: 90.days.ago, to: Time.zone.yesterday),
        notes: "Notes from CMP - Multi Correspondence Seed",
        assigned_by_id: 81,
        updated_by_id: 81,
        veteran_id: veteran.id
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

def initial_id_values
  @file_number ||= 500_000_000
  @participant_id ||= 850_000_000
  while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1))
    @file_number += 100
    @participant_id += 100
  end

  @cmp_packet_number ||= 1_000_000_000
  @cmp_packet_number += 10_000 while ::Correspondence.find_by(cmp_packet_number: @cmp_packet_number + 1)
end

def create_veteran(options = {})
  @file_number += 1
  @participant_id += 1
  params = {
    file_number: format("%<n>09d", n: @file_number),
    participant_id: format("%<n>09d", n: @participant_id),
    ssn: Generators::Random.unique_ssn
  }
  veteran = Generators::Veteran.build(params.merge(options))
  veteran.save!
  veteran.update!(params)
  5.times do
    Appeal.create!(
      veteran_file_number: veteran.file_number,
      receipt_date: Time.zone.now,
      established_at: Time.zone.now,
      docket_type: Constants.AMA_DOCKETS.evidence_submission
    )
  end
  veteran
end

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
def create_correspondences_with_documents
  # correspondences with multiple documents
  10.times do
    veteran = create_veteran
    corres = ::Correspondence.create!(
      uuid: SecureRandom.uuid,
      portal_entry_date: Time.zone.now,
      source_type: "Mail",
      package_document_type_id: 15,
      correspondence_type_id: 8,
      cmp_queue_id: 1,
      cmp_packet_number: @cmp_packet_number,
      va_date_of_receipt: Faker::Date.between(from: 90.days.ago, to: Time.zone.yesterday),
      notes: "This is a note from CMP.",
      assigned_by_id: 81,
      updated_by_id: 81,
      veteran_id: veteran.id
    )
    create_multiple_docs(corres, veteran)
    @cmp_packet_number += 1
  end

  (1..77).each do |package_doc_id|
    veteran = create_veteran
    corres = ::Correspondence.create!(
      uuid: SecureRandom.uuid,
      portal_entry_date: Time.zone.now,
      source_type: "Mail",
      package_document_type_id: package_doc_id,
      correspondence_type_id: 8,
      cmp_queue_id: 1,
      cmp_packet_number: @cmp_packet_number,
      va_date_of_receipt: Faker::Date.between(from: 90.days.ago, to: Time.zone.yesterday),
      notes: "This is a note from CMP.",
      assigned_by_id: 81,
      updated_by_id: 81,
      veteran_id: veteran.id
    )
    CorrespondenceDocument.find_or_create_by(
      document_file_number: veteran.file_number,
      uuid: SecureRandom.uuid,
      vbms_document_type_id: 1250,
      document_type: 1250,
      pages: 30,
      correspondence_id: corres.id
    )
    @cmp_packet_number += 1
  end

  (1..24).each do |corres_type_id|
    veteran = create_veteran
    corres = ::Correspondence.create!(
      uuid: SecureRandom.uuid,
      portal_entry_date: Time.zone.now,
      source_type: "Mail",
      package_document_type_id: 15,
      correspondence_type_id: corres_type_id,
      cmp_queue_id: 1,
      cmp_packet_number: @cmp_packet_number,
      va_date_of_receipt: Faker::Date.between(from: 90.days.ago, to: Time.zone.yesterday),
      notes: "This is a note from CMP.",
      assigned_by_id: 81,
      updated_by_id: 81,
      veteran_id: veteran.id
    )
    CorrespondenceDocument.find_or_create_by(
      document_file_number: veteran.file_number,
      uuid: SecureRandom.uuid,
      vbms_document_type_id: 1250,
      document_type: 1250,
      pages: 30,
      correspondence_id: corres.id
    )
    @cmp_packet_number += 1
  end

  (1..17).each do |cmp_queue_id|
    veteran = create_veteran
    corres = ::Correspondence.create!(
      uuid: SecureRandom.uuid,
      portal_entry_date: Time.zone.now,
      source_type: "Mail",
      package_document_type_id: 15,
      correspondence_type_id: 8,
      cmp_queue_id: cmp_queue_id,
      cmp_packet_number: @cmp_packet_number,
      va_date_of_receipt: Faker::Date.between(from: 90.days.ago, to: Time.zone.yesterday),
      notes: "This is a note from CMP.",
      assigned_by_id: 81,
      updated_by_id: 81,
      veteran_id: veteran.id
    )
    CorrespondenceDocument.find_or_create_by(
      document_file_number: veteran.file_number,
      uuid: SecureRandom.uuid,
      vbms_document_type_id: 1250,
      document_type: 1250,
      pages: 30,
      correspondence_id: corres.id
    )
    @cmp_packet_number += 1
  end
end

def create_multiple_docs(corres, veteran)
  CorrespondenceDocument.find_or_create_by(
    document_file_number: veteran.file_number,
    uuid: SecureRandom.uuid,
    correspondence_id: corres.id,
    document_type: 1250,
    pages: 30,
    vbms_document_type_id: 1250
  )
  CorrespondenceDocument.find_or_create_by(
    document_file_number: veteran.file_number,
    uuid: SecureRandom.uuid,
    correspondence_id: corres.id,
    document_type: 719,
    pages: 20,
    vbms_document_type_id: 719
  )
  CorrespondenceDocument.find_or_create_by(
    document_file_number: veteran.file_number,
    uuid: SecureRandom.uuid,
    correspondence_id: corres.id,
    document_type: 672,
    pages: 10,
    vbms_document_type_id: 672
  )
  CorrespondenceDocument.find_or_create_by(
    document_file_number: veteran.file_number,
    uuid: SecureRandom.uuid,
    correspondence_id: corres.id,
    document_type: 18,
    pages: 5,
    vbms_document_type_id: 18
  )
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength

# Note: Remove after document controller is implemented
def create_static_documents
  Document.create!(vbms_document_id: 3)
  Document.create!(vbms_document_id: 4)
end

def create_document_types
  # Caseflow keeps track of VBMS Document Types at Caseflow::DocumentTypes::TYPES
  # https://github.com/department-of-veterans-affairs/caseflow-commons/blob/master/app/models/caseflow/document_types.rb

  # if VbmsDocumentType table is not empty we should only add the document types we are missing (recently added)
  # else the table is empty, so we should add all the document types
  # This is implemented this way so that if a new document type is added to the module,
  # we do not have to clear the table before running this seed file

  doc_types = []
  if VbmsDocumentType.count > 0
    doc_types = Caseflow::DocumentTypes::TYPES.reject { |key, _value| VbmsDocumentType.exists?(doc_type_id: key) }
  else
    Caseflow::DocumentTypes::TYPES.each do |key, _value|
      doc_types << VbmsDocumentType.new(doc_type_id: key)
    end
  end
  VbmsDocumentType.import(doc_types, validate: false) unless doc_types.empty?
end

# rubocop:disable Metrics/MethodLength
def create_correspondence_types
  correspondence_types_list =
    ["Abeyance",
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
     "Withdrawal of appeal"]

  correspondence_types_list.each do |type|
    CorrespondenceType.find_or_create_by(name: type)
  end
end
# rubocop:enable Metrics/MethodLength

def create_package_document_types
  [
    "0304", "0779", "0781", "0781a", "0820a", "0820b", "0820c", "0820e", "0820f", "082d", "0966", "0995", "0996",
    "10007", "10182", "1330", "1330m", "1900", "1905", "1905c", "1905m", "1995", "1999", "1999b", "21-22",
    "21-22a", "247", "2680", "296", "4138", "4142", "4706b", "4706c", "4718a", "516", "518", "526", "526b",
    "526c", "526ez", "527", "527EZ", "530", "530a", "535", "537", "5490", "5495", "601", "674", "674c",
    "8049", "820", "8416", "8940", "BENE TRVL", "CH 31 APP", "CH36 APP", "CONG INQ", "CONSNT",
    "DBQ", "Debt Dispute", "GRADES/DEGREE", "IU", "NOD", "OMPF", "PMR", "RAMP", "REHAB PLAN", "RFA", "RM",
    "RNI", "SF180", "STR", "VA 9", "VCAA", "VRE INV"
  ].each do |package_document_type|
    PackageDocumentType.find_or_create_by(name: package_document_type)
  end
end

def create_correspondence_veteran(options = {})
  @file_number += 1
  @participant_id += 1
  params = {
    file_number: format("%<n>09d", n: @file_number),
    participant_id: format("%<n>09d", n: @participant_id),
    ssn: Generators::Random.unique_ssn
  }
  veteran = Generators::Veteran.build(params.merge(options))
  veteran.save!
  veteran.update!(params)
  veteran
end

# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
def create_multi_correspondences
  veteran = create_correspondence_veteran(first_name: "Adam", last_name: "West")
  5.times do
    appeal = Appeal.create!(
      veteran_file_number: veteran.file_number,
      receipt_date: Time.zone.now,
      established_at: Time.zone.now,
      docket_type: Constants.AMA_DOCKETS.evidence_submission
    )
    InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
  end
  5.times do
    appeal = Appeal.create!(
      veteran_file_number: veteran.file_number,
      receipt_date: Time.zone.now,
      established_at: Time.zone.now,
      docket_type: Constants.AMA_DOCKETS.evidence_submission
    )
    InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
  end
  21.times do
    corres = ::Correspondence.create!(
      uuid: SecureRandom.uuid,
      portal_entry_date: Time.zone.now,
      source_type: "Mail",
      package_document_type_id: (1..20).to_a.sample,
      correspondence_type_id: 4,
      cmp_queue_id: 1,
      cmp_packet_number: @cmp_packet_number,
      va_date_of_receipt: Faker::Date.between(from: 90.days.ago, to: Time.zone.yesterday),
      notes: "Notes from CMP - Multi Correspondence Seed",
      assigned_by_id: 81,
      updated_by_id: 81,
      veteran_id: veteran.id
    )
    CorrespondenceDocument.find_or_create_by(
      document_file_number: veteran.file_number,
      uuid: SecureRandom.uuid,
      vbms_document_type_id: 1250,
      document_type: 1250,
      pages: 30,
      correspondence_id: corres.id
    )
    @cmp_packet_number += 1
  end

  veteran = create_correspondence_veteran(first_name: "Michael", last_name: "Keaton")
  2.times do
    appeal = Appeal.create!(
      veteran_file_number: veteran.file_number,
      receipt_date: Time.zone.now,
      established_at: Time.zone.now,
      docket_type: Constants.AMA_DOCKETS.evidence_submission
    )
    InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
  end
  5.times do
    appeal = Appeal.create!(
      veteran_file_number: veteran.file_number,
      receipt_date: Time.zone.now,
      established_at: Time.zone.now,
      docket_type: Constants.AMA_DOCKETS.evidence_submission
    )
    InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
  end
  31.times do
    corres = ::Correspondence.create!(
      uuid: SecureRandom.uuid,
      portal_entry_date: Time.zone.now,
      source_type: "Mail",
      package_document_type_id: (1..20).to_a.sample,
      correspondence_type_id: 4,
      cmp_queue_id: 1,
      cmp_packet_number: @cmp_packet_number,
      va_date_of_receipt: Faker::Date.between(from: 90.days.ago, to: Time.zone.yesterday),
      notes: "Notes from CMP - Multi Correspondence Seed",
      assigned_by_id: 81,
      updated_by_id: 81,
      veteran_id: veteran.id
    )
    CorrespondenceDocument.find_or_create_by(
      document_file_number: veteran.file_number,
      uuid: SecureRandom.uuid,
      vbms_document_type_id: 1250,
      document_type: 1250,
      pages: 30,
      correspondence_id: corres.id
    )
    @cmp_packet_number += 1
  end

  veteran = create_correspondence_veteran(first_name: "Christian", last_name: "Bale")
  1.times do
    appeal = Appeal.create!(
      veteran_file_number: veteran.file_number,
      receipt_date: Time.zone.now,
      established_at: Time.zone.now,
      docket_type: Constants.AMA_DOCKETS.evidence_submission
    )
    InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
  end
  10.times do
    appeal = Appeal.create!(
      veteran_file_number: veteran.file_number,
      receipt_date: Time.zone.now,
      established_at: Time.zone.now,
      docket_type: Constants.AMA_DOCKETS.evidence_submission
    )
    InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
  end
  101.times do
    corres = ::Correspondence.create!(
      uuid: SecureRandom.uuid,
      portal_entry_date: Time.zone.now,
      source_type: "Mail",
      package_document_type_id: (1..20).to_a.sample,
      correspondence_type_id: 4,
      cmp_queue_id: 1,
      cmp_packet_number: @cmp_packet_number,
      va_date_of_receipt: Faker::Date.between(from: 90.days.ago, to: Time.zone.yesterday),
      notes: "Notes from CMP - Multi Correspondence Seed",
      assigned_by_id: 81,
      updated_by_id: 81,
      veteran_id: veteran.id
    )
    CorrespondenceDocument.find_or_create_by(
      document_file_number: veteran.file_number,
      uuid: SecureRandom.uuid,
      vbms_document_type_id: 1250,
      document_type: 1250,
      pages: 30,
      correspondence_id: corres.id
    )
    @cmp_packet_number += 1
  end
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize
