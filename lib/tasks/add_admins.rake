# frozen_string_literal: true

namespace :add_admins do
    desc "given the org and a user id, add the users as an admin to the organization"
    task :add_single_admin, [:org_id, :user_id] => :environment do |t, args| 
        org = Organization.find(args[:org_id].to_i)
        user = User.find(args[:user_id].to_i)
        STDOUT.puts("Organization: #{org.name}")
        STDOUT.puts("User to be admin: #{user.full_name}")
        STDOUT.puts("Is this correct? (y/n)")
        input = STDIN.gets.chomp
        if input.downcase == 'y'
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
    task :batch_add_admin do 
        STDOUT.puts("Enter the organization id")
        org_id = STDIN.gets.chomp
        if org_id.to_i.is_a? Integer 
            STDOUT.puts("Enter the user ids to be assigned as admins separated by commas (ex: 1, 2, 3...)")
            input = STDIN.gets.chomp
            user_array = input.split(",")
            user_array.each {|n| n.strip}
            user_array.each do |id| 
                Rake::Task["add_admins:add_single_admin"].reenable
                Rake.application.invoke_task("add_admins:add_single_admin[#{org_id}, #{id}]")
            end
        else
            STDOUT.puts("Improper input... exiting")
        end
    end

    desc "given a user id and a role, assign the role to the user"
    task :assign_role_to_user, [:user_id, :role] => :environment do |t, args| 
        user = User.find(args[:user_id].to_i)
        STDOUT.puts("Do you want to assign #{user.full_name} the role of #{args[:role]}?")
        STDOUT.puts("y/n?")
        input = STDIN.gets.chomp
        if input.downcase == 'y'
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
        STDOUT.puts("Enter the role to assign to the users.")
        role = STDIN.gets.chomp

        STDOUT.puts("Enter the user ids to be assigned the role #{role} separated by commas (ex: 1, 2, 3...)")
        input = STDIN.gets.chomp
        user_array = input.split(",")
        user_array.each {|n| n.strip}

        user_array.each do |id|
            Rake::Task["add_admins:assign_role_to_user"].reenable
            Rake.application.invoke_task("add_admins:assign_role_to_user[#{id},#{role}]")
        end
    end
end
