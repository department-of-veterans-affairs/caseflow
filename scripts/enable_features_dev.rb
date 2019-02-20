# bundle exec rails runner scripts/enable_features_dev.rb

json_config = <<EOS.strip_heredoc
  [
        {
          feature: "intakeAma",
          enable_all: true
        },
        {
          feature: "automatic_ramp_rollback",
          enable_all: true
        },
        {
          feature: "hearings",
          users: ["CASEFLOW_397", "CASEFLOW1"]
        },
        {
          feature: "decision_reviews",
          enable_all: true
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
          feature: "judge_case_review_checkout",
          enable_all: true
        },
        {
          feature: "queue_beaam_appeals",
          enable_all: true
        },
        {
          feature: "attorney_assignment_to_colocated",
          enable_all: true
        },
        {
          feature: "idt_ama_appeals",
          enable_all: true
        },
        {
          feature: "decision_document_upload",
          enable_all: true
        },
        {
          feature: "use_representative_info_from_bgs",
          enable_all: true
        },
        {
          feature: "ama_auto_case_distribution",
          enable_all: true
        },
        {
          feature: "ama_acd_tasks",
          enable_all: true
        },
        {
          feature: "automatic_case_distribution",
          enable_all: true
        }
  ]
EOS

FeatureToggle.sync! json_config
