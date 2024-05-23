# frozen_string_literal: true

# create correspondence seeds
require_relative "./helpers/queue_helpers"

module Seeds
  # :reek:InstanceVariableAssumption
  class MultiCorrespondences < Base

    include QueueHelpers

    def initialize
      initial_id_values
      RequestStore[:current_user] = User.find_by_css_id("BVADWISE") if RequestStore[:current_user].blank?
    end

    # seed with values for UAT rake task correspondence.rake
    # seed without values for Demo (default)
    def seed!(user = {}, veteran = {})
      create_multi_correspondences(user, veteran)
    end

    private

    def initial_id_values
      @file_number ||= 550_000_000
      @participant_id ||= 650_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1))
        @file_number += 100
        @participant_id += 100
      end
    end

    # creates correspondences for given vet (UAT)
    # default, creates Batman vets to assign cases to (demo)
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def create_multi_correspondences(user = {}, veteran = {})
      if user.blank?
        # grab list of inbound ops team base users
        users = InboundOpsTeam.singleton.users.each {|user| user.inbound_ops_team_user? }
        # create veterans
        west = create_veteran(first_name: "Adam", last_name: "West")
        bale = create_veteran(first_name: "Christian", last_name: "Bale")
        keaton = create_veteran(first_name: "Michael", last_name: "Keaton")

        # build correspondences for different users
        build_correspondences(west, users.first, 5)
        build_correspondences(bale, users.second, 10)
        build_correspondences(keaton, users.third, 20)
        return
      end

      # used for UAT correspondence.rake
      build_correspondences(veteran, user, 20)
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def build_correspondences(veteran, user, iterations = 10)
      15.times do
        appeal = create(
          :appeal,
          veteran_file_number: veteran.file_number
        )
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      end
      15.times do
        appeal = create(
          :appeal,
          veteran_file_number: veteran.file_number,
          docket_type: Constants.AMA_DOCKETS.direct_review
        )
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      end
      iterations.times do
        corr = create_correspondence(user, veteran)
        create_correspondence_document(corr, veteran)
        assign_review_package_task(corr, user)
      end
    end
  end
end
