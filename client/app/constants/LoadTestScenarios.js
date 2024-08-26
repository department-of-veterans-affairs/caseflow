export const DEFAULT_TARGET_TYPES = ["Appeal",
   "LegacyAppeal",
    "Hearing",
    "HigherLevelReview",
    "SupplementalClaim",
    "Document",
    "Metric"]

export const LOAD_TEST_SCENARIOS = [
  {
    scenario: "hlrPageTest",
    target_type: ["Appeal"]
  },
  {
    scenario: "appealHearingsTest",
    target_type: ["Appeal"]
  },
  {
    scenario: "scheduleTest",
    target_type: ["Appeal"]
  },
  {
    scenario: "searchTest",
    target_type: ["Appeal"]
  },
  {
    scenario: "appealDocumentCountTest",
    target_type: ["Appeal"]
  },
  {
    scenario: "appealVeteranTest",
    target_type: ["Appeal"]
  },
  {
    scenario: "appealPoaTest",
    target_type: ["Appeal"]
  },
  {
    scenario: "queueTest",
    target_type: ["Appeal"]
  },
  {
    scenario: "queueAppealTest",
    target_type: ["Appeal"]
  },
  {
    scenario: "legacyReaderIndexTest",
    target_type: ["Appeal"]
  },
  {
    scenario: "amaReaderIndexTest",
    target_type: ["Appeal"]
  },
  {
    scenario: "v2MetricLogsTest",
    target_type: ["Appeal"]
  }
];
