export default {
  nonComp: {
    businessLineUrl: 'vha',
    task: {
      claimant: {
        name: 'Jane Smith',
        relationship: 'Child'
      },
      id: 15497,
    },
    isBusinessLineAdmin: true,
    selectedTask: null,
    decisionIssuesStatus: {}
  },
  changeHistory: {
    status: 'idle',
    error: null,
    events: [
      {
        taskID: 15497,
        eventType: 'added_issue_without_decision_date',
        eventUser: 'L. Roth',
        eventDate: '2023-12-09 17:59:58.932798',
        claimType: 'Higher-Level Review',
        readableEventType: 'Added issue - No decision date',
        claimantName: 'Jane Smith',
        details: {
          benefitType: 'vha',
          issueType: null,
          issueDescription: 'unidentified issue description',
          decisionDate: null,
          disposition: null,
          decisionDescription: null,
          withdrawalRequestDate: '2023-12-12 17:59:58.881364'
        },
        id: '803a103c-207b-4f71-9391-b168964c73ed',
        type: 'change_history_event'
      },
      {
        taskID: 15497,
        eventType: 'claim_creation',
        eventUser: 'L. Roth',
        eventDate: '2023-12-09 17:59:58.932798',
        claimType: 'Higher-Level Review',
        readableEventType: 'Claim created',
        claimantName: 'Jane Smith',
        details: {
          benefitType: 'vha',
          issueType: null,
          issueDescription: null,
          decisionDate: null,
          disposition: null,
          decisionDescription: null,
          withdrawalRequestDate: null
        },
        id: '1b5dc8c8-c1ea-4596-a51c-73cc8ecd45b5',
        type: 'change_history_event'
      },
      {
        taskID: 15497,
        eventType: 'incomplete',
        eventUser: 'System',
        eventDate: '2023-12-09T17:59:58Z',
        claimType: 'Higher-Level Review',
        readableEventType: 'Claim status - Incomplete',
        claimantName: 'Jane Smith',
        details: {
          benefitType: 'vha',
          issueType: null,
          issueDescription: null,
          decisionDate: null,
          disposition: null,
          decisionDescription: null,
          withdrawalRequestDate: null
        },
        id: '93b5cb42-136d-44a3-9e96-b18eb0397291',
        type: 'change_history_event'
      },
      {
        taskID: 15497,
        eventType: 'added_issue',
        eventUser: 'S. User',
        eventDate: '2023-12-12 17:59:58.887898',
        claimType: 'Higher-Level Review',
        readableEventType: 'Added issue',
        claimantName: 'Jane Smith',
        details: {
          benefitType: 'vha',
          issueType: 'Other',
          issueDescription: 'issue added after removing unidentified issues',
          decisionDate: '2023-09-12',
          disposition: null,
          decisionDescription: null,
          withdrawalRequestDate: '2024-02-23 13:57:29.458451'
        },
        id: 'eddde370-0714-4905-b6b0-5672e14bb588',
        type: 'change_history_event'
      },
      {
        taskID: 15497,
        eventType: 'removed_issue',
        eventUser: 'S. User',
        eventDate: '2023-12-12 17:59:58.910779',
        claimType: 'Higher-Level Review',
        readableEventType: 'Removed issue',
        claimantName: 'Jane Smith',
        details: {
          benefitType: 'vha',
          issueType: null,
          issueDescription: 'unidentified issue description',
          decisionDate: null,
          disposition: null,
          decisionDescription: null,
          withdrawalRequestDate: '2023-12-12 17:59:58.881364'
        },
        id: 'a4a3ba54-0386-4efe-aa26-4bebc759bca0',
        type: 'change_history_event'
      },
      {
        taskID: 15497,
        eventType: 'in_progress',
        eventUser: 'System',
        eventDate: '2023-12-12T17:59:58Z',
        claimType: 'Higher-Level Review',
        readableEventType: 'Claim status - In progress',
        claimantName: 'Jane Smith',
        details: {
          benefitType: 'vha',
          issueType: null,
          issueDescription: null,
          decisionDate: null,
          disposition: null,
          decisionDescription: null,
          withdrawalRequestDate: null
        },
        id: '529ccae8-3764-4a99-8b21-a090cd99c07d',
        type: 'change_history_event'
      },
      {
        taskID: 15497,
        eventType: 'added_issue',
        eventUser: 'V. ',
        eventDate: '2024-02-23 13:57:29.431876',
        claimType: 'Higher-Level Review',
        readableEventType: 'Added issue',
        claimantName: 'Jane Smith',
        details: {
          benefitType: 'vha',
          issueType: 'Beneficiary Travel',
          issueDescription: 'go fly',
          decisionDate: '2024-02-23',
          disposition: null,
          decisionDescription: null,
          withdrawalRequestDate: null
        },
        id: '50939ea7-0ef9-4382-af16-83c37b5ce6ad',
        type: 'change_history_event'
      },
      {
        taskID: 15497,
        eventType: 'removed_issue',
        eventUser: 'V. ',
        eventDate: '2024-02-23 13:57:29.609266',
        claimType: 'Higher-Level Review',
        readableEventType: 'Removed issue',
        claimantName: 'Jane Smith',
        details: {
          benefitType: 'vha',
          issueType: 'Other',
          issueDescription: 'issue added after removing unidentified issues',
          decisionDate: '2023-09-12',
          disposition: null,
          decisionDescription: null,
          withdrawalRequestDate: '2024-02-23T08:57:29.458-05:00'
        },
        id: '42cf428c-802d-45e6-a82a-fec4ba81ed59',
        type: 'change_history_event'
      }
    ],
    fetchIndividualHistory: {
      status: 'succeeded'
    }
  }
};
