export default {
  savedSearch: {
    saveUserSearch: {
      radioStatus: 'all_statuses',
      radioStatusReportType: 'last_action_taken',
      reportType: 'status',
      timing: {
        range: null
      },
      conditions: [
        {
          options: {
            comparisonOperator: 'lessThan',
            valueOne: 5
          },
          condition: 'daysWaiting'
        },
        {
          condition: 'issueType',
          options: {
            issueTypes: [
              {
                value: 'Camp Lejune Family Member',
                label: 'Camp Lejune Family Member'
              },
              {
                value: 'Caregiver | Eligibility',
                label: 'Caregiver | Eligibility'
              }
            ]
          }
        },
        {
          condition: 'issueDisposition',
          options: {
            issueDispositions: [
              {
                label: 'Blank',
                value: 'blank'
              },
              {
                label: 'Denied',
                value: 'denied'
              },
              {
                label: 'Dismissed',
                value: 'dismissed'
              }
            ]
          }
        },
        {
          condition: 'decisionReviewType',
          options: {
            decisionReviewTypes: [
              {
                label: 'Higher-Level Reviews',
                value: 'HigherLevelReview'
              },
              {
                label: 'Supplemental Claims',
                value: 'SupplementalClaim'
              }
            ]
          }
        },
        {
          condition: 'personnel',
          options: {
            personnel: [
              {
                label: 'Karmen Deckow DDS',
                value: 'PTBRADFAVBAS'
              },
              {
                label: 'Gerard Parisian LLD',
                value: 'THOMAW2VACO'
              }
            ]
          }
        }
      ]
    }
  }
};
