json_config = <<EOS
[
      {
        feature: "intakeAma",
        enable_all: true
      },
      {
        feature: "appeals_status",
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
        feature: "dispatch_full_grants",
        enable_all: true
      },
      {
        feature: "dispatch_partial_grants_remands",
        regional_offices: ["RO97"]
      },
      {
        feature: "dispatch_full_grants_with_pa",
        enable_all: true
      },
      {
        feature: "efolder_api_v2",
        enable_all: true
      },
      {
        feature: "efolder_docs_api",
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
        feature: "vbms_efolder_service_v1",
        enable_all: true
      },
      {
        feature: "queue_case_search",
        enable_all: true
      },
      {
        feature: "judge_queue",
        enable_all: true
      }
]
EOS
FeatureToggle.sync! json_config
