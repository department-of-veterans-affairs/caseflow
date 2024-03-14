# frozen_string_literal: true

require_relative "../../db/seeds/base"
require_relative "../../db/seeds/correspondence"
require_relative "../../db/seeds/vbms_document_types"
require_relative "../../db/seeds/correspondence_types"
require_relative "../../db/seeds/package_document_types"
require_relative "../../db/seeds/multi_correspondences"
require_relative "../../db/seeds/queue_correspondences"

namespace :correspondence do
  desc "setup data for intake correspondence (autotext and correspondence type)in UAT/PROD"
  task :setup_correspondence_data, [] => :environment do |_|
    STDOUT.puts("Creating data for Auto Text Table")
    create_auto_text_table
    STDOUT.puts("Creating data for VBMS Document Types Table")
    create_document_types
    STDOUT.puts("Creating data for Correspondence Types Table")
    create_correspondence_types
    STDOUT.puts("Creating data for Package Document Types Table")
    create_package_document_types
  end

  desc "create correspondence test data in UAT given a veteran file number"
  task :create_correspondence_test_data, [] => :environment do |_|
    catch(:error) do
      throw :error, STDOUT.puts("Please add a user to the request store") if RequestStore[:current_user].blank?
      STDOUT.puts("This script will create correspondences from queue_correspondences.rb and\n
        multi_correspondences.rb for a veteran based off their file number\n
        These will be assigned to RequstStore[:current_user] (currently
          #{RequestStore[:current_user].css_id})")
      STDOUT.puts("Enter the veteran's file number")
      veteran_file_number = STDIN.gets.chomp

      vet = Veteran.find_by_file_number_or_ssn(veteran_file_number)
      throw :error, STDOUT.puts("Veteran cannot be found") if vet.blank?

      STDOUT.puts("Running multi_correspondences.rb")
      Seeds::MultiCorrespondences.new.seed!(RequestStore[:current_user], vet)

      STDOUT.puts("Running queue_correspondences.rb")
      Seeds::QueueCorrespondences.new.seed!(RequestStore[:current_user], vet)
      STDOUT.puts("Success!! Correspondences have been seeded. Well done friend!")
    end
  end
end

# rubocop:disable Metrics/MethodLength
def create_auto_text_table
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
end
# rubocop:enable Metrics/MethodLength

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
