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
  savedSearches: {
    fetchedSearches: {
      status: 'idle',
      error: null,
      allSearches: [
        {
          id: 1,
          name: 'Search Name',
          description: 'Search Description is interesting to be done. Long Desciption goes here. how long is too long',
          createdAt: '2024-10-21T06:00:00.000Z',
          saved_params: {
            report_type: 'event_type_action',
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          },
          user: {
            id: 12,
            cssId: 'VHAADMIN',
            fullName: 'VHAADMIN',
          }
        },
        {
          id: 2,
          name: 'Search Name2',
          description: 'Search Description2 is interesting to be done.',
          createdAt: '2024-10-11T06:00:00.000Z',
          user: {
            id: 12,
            cssId: 'VHAADMIN',
            fullName: 'VHAADMIN',
          },
          saved_params: {
            report_type: 'event_type_action',
            events: {
              0: 'added_decision_date',
              1: 'added_issue',
              2: 'added_issue_no_decision_date',
              3: 'claim_created',
              4: 'claim_closed'
            },
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 3,
          name: 'Search Name3',
          description: 'Search Description3 is interesting to be done.',
          createdAt: '2024-10-12T06:00:00.000Z',
          user: {
            id: 13,
            cssId: 'VHAADMIN2',
            fullName: 'VHAADMIN2',
          },
          saved_params: {
            report_type: 'event_type_action',
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 4,
          name: 'Search Name4',
          description: 'Search Description4 is interesting to be done.',
          createdAt: '2024-07-13T06:00:00.000Z',
          user: {
            id: 14,
            cssId: 'VHAADMIN3',
            fullName: 'VHAADMIN3',
          },
          saved_params: {
            report_type: 'event_type_action',
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 5,
          name: 'Search Name',
          description: 'Search Description is interesting to be done.',
          createdAt: '2024-07-10T06:00:00.000Z',
          user: {
            id: 12,
            cssId: 'VHAADMIN',
            fullName: 'VHAADMIN',
          },
          saved_params: {
            report_type: 'event_type_action',
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 6,
          name: 'Search Name2',
          description: 'Search Description2 is interesting to be done.',
          createdAt: '2024-07-11T06:00:00.000Z',
          user: {
            id: 12,
            cssId: 'VHAADMIN',
            fullName: 'VHAADMIN',
          },
          saved_params: {
            report_type: 'event_type_action',
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 7,
          name: 'Search Name3',
          description: 'Search Description3 is interesting to be done.',
          createdAt: '2024-07-12T06:00:00.000Z',
          user: {
            id: 13,
            cssId: 'VHAADMIN2',
            fullName: 'VHAADMIN2',
          },
          saved_params: {
            report_type: 'event_type_action',
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 8,
          name: 'Search Name4',
          description: 'Search Description4 is interesting to be done.',
          createdAt: '2024-07-13T06:00:00.000Z',
          user: {
            id: 14,
            cssId: 'VHAADMIN3',
            fullName: 'VHAADMIN3',
          },
          saved_params: {
            report_type: 'event_type_action',
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 9,
          name: 'Search Name',
          description: 'Search Description is interesting to be done.',
          createdAt: '2024-07-16T06:00:00.000Z',
          user: {
            id: 12,
            cssId: 'VHAADMIN',
            fullName: 'VHAADMIN',
          },
          saved_params: {
            report_type: 'event_type_action',
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 10,
          name: 'Search Name2',
          description: 'Search Description2 is interesting to be done.',
          createdAt: '2024-07-21T06:00:00.000Z',
          user: {
            id: 12,
            cssId: 'VHAADMIN',
            fullName: 'VHAADMIN',
          },
          saved_params: {
            report_type: 'event_type_action',
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 11,
          name: 'Search Name3',
          description: 'Search Description3 is interesting to be done.',
          createdAt: '2024-07-15T06:00:00.000Z',
          user: {
            id: 13,
            cssId: 'VHAADMIN2',
            fullName: 'VHAADMIN2',
          },
          saved_params: {
            report_type: 'event_type_action',
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 12,
          name: 'Search Name4',
          description: 'Search Description4 is interesting to be done.',
          createdAt: '2024-07-11T06:00:00.000Z',
          user: {
            id: 14,
            cssId: 'VHAADMIN3',
            fullName: 'VHAADMIN3',
          },
          saved_params: {
            report_type: 'event_type_action',
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 13,
          name: 'Search Name4',
          description: 'Search Description4 is interesting to be done.',
          createdAt: '2024-07-13T06:00:00.000Z',
          user: {
            id: 14,
            cssId: 'VHAADMIN3',
            fullName: 'VHAADMIN3',
          },
          saved_params: {
            report_type: 'event_type_action',
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 14,
          name: 'Search Name4',
          description: 'Search Description4 is interesting to be done.',
          createdAt: '2024-07-13T06:00:00.000Z',
          user: {
            id: 14,
            cssId: 'VHAADMIN3',
            fullName: 'VHAADMIN3',
          },
          saved_params: {
            report_type: 'event_type_action',
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 15,
          name: 'Search Name4',
          description: 'Search Description4 is interesting to be done.',
          createdAt: '2024-07-23T06:00:00.000Z',
          user: {
            id: 14,
            cssId: 'VHAADMIN3',
            fullName: 'VHAADMIN3',
          },
          saved_params: {
            report_type: 'event_type_action',
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 16,
          name: 'Search Name4',
          description: 'Search Description4 is interesting to be done.',
          createdAt: '2024-07-23T06:00:00.000Z',
          user: {
            id: 14,
            cssId: 'VHAADMIN3',
            fullName: 'VHAADMIN3',
          },
          saved_params: {
            report_type: 'event_type_action',
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 17,
          name: 'Search Name2',
          description: 'Search Description2 is interesting to be done.',
          createdAt: '2024-10-11T06:00:00.000Z',
          user: {
            id: 12,
            cssId: 'VHAADMIN',
            fullName: 'VHAADMIN',
          },
          saved_params: {
            report_type: 'event_type_action',
            events: {
              0: 'added_decision_date',
              1: 'added_issue',
              2: 'added_issue_no_decision_date',
              3: 'claim_created',
              4: 'claim_closed'
            },
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 18,
          name: 'Search Name2',
          description: 'Search Description2 is interesting to be done.',
          createdAt: '2024-10-11T06:00:00.000Z',
          user: {
            id: 12,
            cssId: 'VHAADMIN',
            fullName: 'VHAADMIN',
          },
          saved_params: {
            report_type: 'event_type_action',
            events: {
              0: 'added_decision_date',
              1: 'added_issue',
              2: 'added_issue_no_decision_date',
              3: 'claim_created',
              4: 'claim_closed'
            },
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 19,
          name: 'Search Name2',
          description: 'Search Description2 is interesting to be done.',
          createdAt: '2024-10-11T06:00:00.000Z',
          user: {
            id: 12,
            cssId: 'VHAADMIN',
            fullName: 'VHAADMIN',
          },
          saved_params: {
            report_type: 'event_type_action',
            events: {
              0: 'added_decision_date',
              1: 'added_issue',
              2: 'added_issue_no_decision_date',
              3: 'claim_created',
              4: 'claim_closed'
            },
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        },
        {
          id: 20,
          name: 'Search Name2',
          description: 'Search Description2 is interesting to be done.',
          createdAt: '2024-10-11T06:00:00.000Z',
          user: {
            id: 12,
            cssId: 'VHAADMIN',
            fullName: 'VHAADMIN',
          },
          saved_params: {
            report_type: 'event_type_action',
            events: {
              0: 'added_decision_date',
              1: 'added_issue',
              2: 'added_issue_no_decision_date',
              3: 'claim_created',
              4: 'claim_closed'
            },
            timing: {
              range: 'after',
              start_date: '2024-10-07T06:00:00.000Z'
            }
          }
        }
      ],
      userSearches: [{
        id: 10,
        name: 'Search Name2',
        description: 'Search Description2 is interesting to be done.',
        createdAt: '2024-07-21T06:00:00.000Z',
        user: {
          id: 12,
          cssId: 'VHAADMIN',
          fullName: 'VHAADMIN',
        },
        saved_params: {
          report_type: 'event_type_action',
          timing: {
            range: 'after',
            start_date: '2024-10-07T06:00:00.000Z'
          }
        }
      },
      {
        id: 11,
        name: 'Search Name3',
        description: 'Search Description3 is interesting to be done.',
        createdAt: '2024-07-15T06:00:00.000Z',
        user: {
          id: 12,
          cssId: 'VHAADMIN',
          fullName: 'VHAADMIN',
        },
        saved_params: {
          report_type: 'event_type_action',
          timing: {
            range: 'after',
            start_date: '2024-10-07T06:00:00.000Z'
          }
        }
      },
      {
        id: 12,
        name: 'Search Name4',
        description: 'Search Description4 is interesting to be done.',
        createdAt: '2024-07-11T06:00:00.000Z',
        user: {
          id: 12,
          cssId: 'VHAADMIN',
          fullName: 'VHAADMIN',
        },
        saved_params: {
          report_type: 'event_type_action',
          timing: {
            range: 'after',
            start_date: '2024-10-07T06:00:00.000Z'
          }
        }
      },
      {
        id: 13,
        name: 'Search Name4',
        description: 'Search Description4 is interesting to be done.',
        createdAt: '2024-07-13T06:00:00.000Z',
        user: {
          id: 12,
          cssId: 'VHAADMIN',
          fullName: 'VHAADMIN',
        },
        saved_params: {
          report_type: 'event_type_action',
          timing: {
            range: 'after',
            start_date: '2024-10-07T06:00:00.000Z'
          }
        }
      },
      {
        id: 14,
        name: 'Search Name4',
        description: 'Search Description4 is interesting to be done.',
        createdAt: '2024-07-13T06:00:00.000Z',
        user: {
          id: 12,
          cssId: 'VHAADMIN',
          fullName: 'VHAADMIN',
        },
        saved_params: {
          report_type: 'event_type_action',
          timing: {
            range: 'after',
            start_date: '2024-10-07T06:00:00.000Z'
          }
        }
      },
      {
        id: 15,
        name: 'Search Name4',
        description: 'Search Description4 is interesting to be done.',
        createdAt: '2024-07-23T06:00:00.000Z',
        user: {
          id: 12,
          cssId: 'VHAADMIN',
          fullName: 'VHAADMIN',
        },
        saved_params: {
          report_type: 'event_type_action',
          timing: {
            range: 'after',
            start_date: '2024-10-07T06:00:00.000Z'
          }
        }
      },
      {
        id: 16,
        name: 'Search Name4',
        description: 'Search Description4 is interesting to be done.',
        createdAt: '2024-07-23T06:00:00.000Z',
        user: {
          id: 12,
          cssId: 'VHAADMIN',
          fullName: 'VHAADMIN',
        },
        saved_params: {
          report_type: 'event_type_action',
          timing: {
            range: 'after',
            start_date: '2024-10-07T06:00:00.000Z'
          }
        }
      },
      {
        id: 17,
        name: 'Search Name2',
        description: 'Search Description2 is interesting to be done.',
        createdAt: '2024-10-11T06:00:00.000Z',
        user: {
          id: 12,
          cssId: 'VHAADMIN',
          fullName: 'VHAADMIN',
        },
        saved_params: {
          report_type: 'event_type_action',
          events: {
            0: 'added_decision_date',
            1: 'added_issue',
            2: 'added_issue_no_decision_date',
            3: 'claim_created',
            4: 'claim_closed'
          },
          timing: {
            range: 'after',
            start_date: '2024-10-07T06:00:00.000Z'
          }
        }
      },
      {
        id: 18,
        name: 'Search Name2',
        description: 'Search Description2 is interesting to be done.',
        createdAt: '2024-10-11T06:00:00.000Z',
        user: {
          id: 12,
          cssId: 'VHAADMIN',
          fullName: 'VHAADMIN',
        },
        saved_params: {
          report_type: 'event_type_action',
          events: {
            0: 'added_decision_date',
            1: 'added_issue',
            2: 'added_issue_no_decision_date',
            3: 'claim_created',
            4: 'claim_closed'
          },
          timing: {
            range: 'after',
            start_date: '2024-10-07T06:00:00.000Z'
          }
        }
      },
      {
        id: 20,
        name: 'Search Name2',
        description: 'Search Description2 is interesting to be done.',
        createdAt: '2024-10-11T06:00:00.000Z',
        user: {
          id: 12,
          cssId: 'VHAADMIN',
          fullName: 'VHAADMIN',
        },
        saved_params: {
          report_type: 'event_type_action',
          events: {
            0: 'added_decision_date',
            1: 'added_issue',
            2: 'added_issue_no_decision_date',
            3: 'claim_created',
            4: 'claim_closed'
          },
          timing: {
            range: 'after',
            start_date: '2024-10-07T06:00:00.000Z'
          }
        }
      }]
    },
    fetchIndividualHistory: {
      status: 'succeeded'
    }
  }
};
