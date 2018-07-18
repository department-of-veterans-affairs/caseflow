# bundle exec rails runner scripts/enable_features_dev.rb

json_config = <<EOS.strip_heredoc
  [
        {
          feature: "intakeAma",
          enable_all: true
        },
        {
          feature: "queue_welcome_gate",
          enable_all: true
        },
        {
          feature: "queue_phase_two",
          enable_all: true
        },
        {
          feature: "hearings",
          users: ["CASEFLOW_397", "CASEFLOW1"]
        },
        {
          feature: "intake",
          enable_all: true
        },
        {
          feature: "reader",
          enable_all: true
        },
        {
          feature: "search",
          enable_all: true
        },
        {
          feature: "judge_queue",
          enable_all: true
        },
        {
          feature: "colocated_queue",
          enable_all: true
        },
        {
          feature: "judge_case_review_checkout",
          enable_all: true
        },
        {
          feature: "queue_beaam_appeals",
          enable_all: true
        },
        {
          feature: "judge_assignment_to_attorney",
          enable_all: true
        },
        {
          feature: "attorney_assignment_to_colocated",
          enable_all: true
        }
  ]
EOS

FeatureToggle.sync! json_config
