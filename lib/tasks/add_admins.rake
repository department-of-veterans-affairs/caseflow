# frozen_string_literal: true

namespace :add_admins do
  desc "given the org and a user id, add the users as an admin to the organization"
  task :add_single_admin, [:org_id, :user_id] => :environment do |_t, args|
    org = Organization.find(args[:org_id].to_i)
    user = User.find(args[:user_id].to_i)
    STDOUT.puts("Organization: #{org.name}")
    STDOUT.puts("User to be admin: #{user.full_name}")
    STDOUT.puts("Is this correct? (y/n)")
    input = STDIN.gets.chomp
    if input.casecmp("y").zero?
      OrganizationsUser.make_user_admin(user, org)
      if OrganizationsUser.find_by(organization_id: org.id, user_id: user.id).nil?
        STDOUT.puts("User #{user.full_name} with ID #{user.id} not added to #{org.name}.")
      else
        STDOUT.puts("User #{user.full_name} with ID #{user.id} successfully added to #{org.name}!")
      end
    else
      STDOUT.puts("Aborting...")
    end
  end

  desc "given the org id and an array of user ids, batch add users as admins"
  task :batch_add_admins do
    STDOUT.puts("Enter the organization id")
    org_id = STDIN.gets.chomp
    if org_id.to_i.is_a? Integer
      STDOUT.puts("Enter the user ids to be assigned as admins separated by commas (ex: 1, 2, 3...)")
      input = STDIN.gets.chomp
      user_array = input.split(",")
      user_array.each(&:strip)
      user_array.each do |id|
        Rake.application.invoke_task("add_admins:add_single_admin[#{org_id}, #{id}]")
        Rake::Task["add_admins:add_single_admin"].reenable
      end
    else
      STDOUT.puts("Improper input... exiting")
    end
  end

  desc "given a user id and a role, assign the role to the user"
  task :assign_role_to_user, [:user_id, :role] => :environment do |_t, args|
    user = User.find(args[:user_id].to_i)
    STDOUT.puts("Do you want to assign #{user.full_name} the role of #{args[:role]}?")
    STDOUT.puts("y/n?")
    input = STDIN.gets.chomp
    if input.casecmp("y").zero?
      user_roles = user.roles
      new_roles = user_roles << args[:role]
      user.update!(roles: new_roles)
      STDOUT.puts("The user's roles are now #{user.roles}")
    else
      STDOUT.puts("Aborting...")
    end
  end

  desc "given a list of user ids, batch assign roles to the users"
  task :batch_assign_roles do
    STDOUT.puts("Enter the role to assign to the users. (example: Case Details, Reader, etc.)")
    role = STDIN.gets.chomp
    STDOUT.puts("Enter the user ids to be assigned the role #{role} separated by commas (ex: 1, 2, 3...)")
    input = STDIN.gets.chomp
    user_array = input.split(",")
    user_array.each(&:strip)
    user_array.each do |id|
      Rake.application.invoke_task("add_admins:assign_role_to_user[#{id},#{role}]")
      Rake::Task["add_admins:assign_role_to_user"].reenable
    end
  end

  desc "create SSC org and test users for UAT testing"
  task :create_ssc_and_users do
    STDOUT.puts("Creating the SSC org and all test users")
    SupervisorySeniorCouncil.singleton
    ussc = User.create!(
      station_id: 101,
      css_id: "SPLTAPPLJERRY",
      full_name: "Jerry SupervisorySeniorCouncilUser",
      roles: ["Hearing Prep"]
    )
    SupervisorySeniorCouncil.singleton.add_user(ussc)
    STDOUT.puts("Created user #{ussc.css_id}")
    ussc2 = User.create!(
      station_id: 101,
      css_id: "SPLTAPPLTOM",
      full_name: "Tom SupervisorySeniorCouncilUser",
      roles: ["Hearing Prep"]
    )
    SupervisorySeniorCouncil.singleton.add_user(ussc2)
    STDOUT.puts("Created user #{ussc2.css_id}")
    ussccr = User.create!(
      station_id: 101,
      css_id: "SPLTAPPLBILLY",
      full_name: "Billy SupervisorySeniorCouncilCaseReviewUser",
      roles: ["Hearing Prep"]
    )
    SupervisorySeniorCouncil.singleton.add_user(ussccr)
    STDOUT.puts("Created user #{ussccr.css_id}")
    CaseReview.singleton.add_user(ussccr)
    ussccr2 = User.create!(
      station_id: 101,
      css_id: "SPLTAPPLSUSAN",
      full_name: "Susan SupervisorySeniorCouncilCaseReviewUser",
      roles: ["Hearing Prep"]
    )
    SupervisorySeniorCouncil.singleton.add_user(ussccr2)
    CaseReview.singleton.add_user(ussccr2)
    STDOUT.puts("Created user #{ussccr2.css_id}")

    # create COB users
    atty = User.create!(
      station_id: 101,
      css_id: "COB_USER_CLARK",
      full_name: "Clark ClerkOfTheBoardUser Kent",
      roles: ["Hearing Prep"]
    )
    ClerkOfTheBoard.singleton.add_user(atty)

    judge = User.create!(
      station_id: 101,
      full_name: "Judy COTB Judge",
      css_id: "BVACOTBJUDGEJUDY",
      roles: ["Hearing Prep"]
    )
    # create!(:staff, :judge_role, sdomainid: judge.css_id)
    ClerkOfTheBoard.singleton.add_user(judge)

    admin = User.create!(
      station_id: 101,
      full_name: "Adam ClerkOfTheBoardAdmin West",
      css_id: "BVATCOBBADMIN",
      roles: ["Hearing Prep"]
    )
    ClerkOfTheBoard.singleton.add_user(admin)
    OrganizationsUser.make_user_admin(admin, ClerkOfTheBoard.singleton)
  end

  desc "create an appellant substitution for a designated appeal"
  task :create_appellant_substitution do
    STDOUT.puts("Enter the appeal id you want to add an appellant substitution to.")
    appeal_id = STDIN.gets.chomp
    appeal = Appeal.find(appeal_id.to_i)
    # set the current user to an SSC user
    RequestStore[:current_user] = User.find_by_css_id "SPLTAPPLBILLY"
    as = AppellantSubstitution.create!(
      created_by: RequestStore[:current_user],
      source_appeal: appeal,
      substitution_date: 5.days.ago.to_date,
      claimant_type: 'VeteranClaimant',
      substitute_participant_id: 500001891,
      poa_participant_id: 600153863
    )
    appeal.appellant_substitution = as

    STDOUT.puts("new appellant substitution: #{as}")
    STDOUT.puts("New appellant substitution made for appeal #{appeal.id} with vet file number #{appeal.veteran_file_number}")
  end

  desc "create a NOD Date Update for a designated appeal"
  task :create_nod_update do
    STDOUT.puts("Enter the appeal id you want to add a NOD date update to.")
    appeal_id = STDIN.gets.chomp
    appeal = Appeal.find(appeal_id.to_i)
    # set the current user to an SSC user
    RequestStore[:current_user] = User.find_by_css_id "SPLTAPPLBILLY"
    nod = NodDateUpdate.create!(
      appeal_id: appeal.id,
      change_reason: "entry_error",
      new_date: Date.new,
      old_date: 5.days.ago.to_date,
      user_id: RequestStore[:current_user].id
    )
    appeal.nod_date_updates = [nod]

    STDOUT.puts("new nod date update: #{nod}")
    STDOUT.puts("New NOD date update made for appeal #{appeal.id} with vet file number #{appeal.veteran_file_number}")
  end

  desc "create an IHP Draft for a designated appeal"
  task :create_ihp_draft do
    STDOUT.puts("Enter the appeal id you want to add an IHP Draft to.")
    appeal_id = STDIN.gets.chomp
    appeal = Appeal.find(appeal_id.to_i)
    # create a default path
    path = "\\\\vacoappbva3.dva.va.gov\\DMDI$\\VBMS Paperless IHPs\\AML\\AMA IHPs\\VetName 12345.pdf"

    ihp = IhpDraft.create!(
      appeal_id: appeal.id,
      appeal_type: "Appeal",
      organization_id: Organization.find_by(name: "Supervisory Senior Council").id,
      path: path
    )

    STDOUT.puts("new ihp created: #{ihp}")
    STDOUT.puts("New IHP draft update made for appeal #{appeal.id} with vet file number #{appeal.veteran_file_number}")
  end
end
