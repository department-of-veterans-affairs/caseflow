/* eslint-disable max-lines */
const uiData = {
  ui: {
  highlightFormItems: false,
  messages: {
    success: null,
    error: null
    },
  saveState: {
    savePending: false,
    saveSuccessful: null
    },
  featureToggles: {
    collect_video_and_central_emails: true,
    enable_hearing_time_slots: true,
    schedule_veteran_virtual_hearing: true,
    overtime_revamp: true,
    overtime_persistence: true,
    mdr_cavc_remand: true,
    reversal_cavc_remand: true,
    dismissal_cavc_remand: true,
    editNodDate: true,
    fnod_badge: true,
    fnod_banner: true,
    view_nod_date_updates: true,
    poa_button_refresh: true,
    poa_auto_refresh: true,
    poa_auto_ihp_update: true,
    edit_unrecognized_appellant: true,
    edit_unrecognized_appellant_poa: true,
    listed_granted_substitution_before_dismissal: true,
    restrict_poa_visibility: true,
    vha_predocket_workflow: true,
    vha_irregular_appeals: true,
    vso_virtual_opt_in: true,
    das_case_timeliness: true
    }
  }
};  

export const camoToBvaIntakeData = {
  queue: {
    amaTasks: {
      7931: {
        uniqueId: '7931',
        isLegacy: false,
        type: 'VhaDocumentSearchTask',
        appealType: 'Appeal',
        addedByCssId: null,
        appealId: 1898,
        externalAppealId: '419ce568-387c-4ac6-a5f5-00a1554cea36',
        assignedOn: '2022-08-06T21:50:24.435-04:00',
        closestRegionalOffice: null,
        createdAt: '2022-08-03T15:07:05.458-04:00',
        closedAt: null,
        startedAt: '2022-08-03T15:07:05.490-04:00',
        assigneeName: 'VHA CAMO',
        assignedTo: {
          cssId: null,
          name: 'VHA CAMO',
          id: 31,
          isOrganization: true,
          type: 'VhaCamo'
        },
        assignedBy: {
          firstName: 'Ignacio',
          lastName: 'Shaw',
          cssId: 'BVAISHAW',
          pgId: 18
        },
        cancelledBy: {
          cssId: null
        },
        cancelReason: null,
        convertedBy: {
          cssId: null
        },
        convertedOn: null,
        taskId: '7931',
        parentId: 7930,
        label: 'Review Documentation',
        documentId: null,
        externalHearingId: null,
        workProduct: null,
        previousTaskAssignedOn: null,
        placedOnHoldAt: null,
        status: 'assigned',
        onHoldDuration: null,
        instructions: [],
        decisionPreparedBy: null,
        availableActions: [
          {
            func: 'vha_assign_to_program_office_data',
            label: 'Assign to Program Office',
            value: 'modal/assign_to_program_office',
            data: {
              options: [
                {
                  label: 'Community Care - Payment Operations Management',
                  value: 33
                },
                {
                  label: 'Community Care - Veteran and Family Members Program',
                  value: 34
                },
                {
                  label: 'Member Services - Health Eligibility Center',
                  value: 35
                },
                {
                  label: 'Member Services - Beneficiary Travel',
                  value: 36
                },
                {
                  label: 'Prosthetics',
                  value: 37
                }
              ],
              modal_title: 'Assign to Program Office',
              modal_body: 'Provide instructions and context for this action:',
              modal_selector_placeholder: 'Select Program Office',
              type: 'AssessDocumentationTask',
              redirect_after: '/organizations/vha-camo'
            }
          },
          {
            func: 'vha_send_to_board_intake',
            label: 'Send to Board Intake',
            value: 'modal/vha_send_to_board_intake',
            data: {
              modal_title: 'Send to Board Intake',
              type: 'VhaDocumentSearchTask',
              redirect_after: '/organizations/vha-camo'
            }
          }
        ],
        timelineTitle: 'VhaDocumentSearchTask completed',
        hideFromQueueTableView: false,
        hideFromTaskSnapshot: false,
        hideFromCaseTimeline: false,
        availableHearingLocations: [],
        latestInformalHearingPresentationTask: {},
        canMoveOnDocketSwitch: true,
        timerEndsAt: null,
        unscheduledHearingNotes: {}
      }
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1898',
        appellant_hearing_email_recipient: null,
        representative_hearing_email_recipient: null,
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36',
        docketName: 'evidence_submission',
        withdrawn: false,
        removed: false,
        overtime: false,
        contestedClaim: false,
        veteranAppellantDeceased: false,
        isLegacyAppeal: false,
        caseType: 'Original',
        isAdvancedOnDocket: false,
        issueCount: 0,
        docketNumber: '220802-1898',
        assignedAttorney: null,
        assignedJudge: null,
        distributedToJudge: false,
        veteranFullName: 'Bob Smithhansen',
        veteranFileNumber: '500000262',
        isPaperCase: false,
        readableHearingRequestType: null,
        readableOriginalHearingRequestType: null,
        vacateType: null,
        hearings: [],
        currentUserEmail: null,
        currentUserTimezone: 'America/New_York',
        completedHearingOnPreviousAppeal: false,
        issues: [],
        decisionIssues: [],
        canEditRequestIssues: false,
        unrecognizedAppellantId: null,
        appellantIsNotVeteran: false,
        appellantFullName: 'Bob Smithhansen',
        appellantFirstName: 'Bob',
        appellantMiddleName: null,
        appellantLastName: 'Smithhansen',
        appellantSuffix: null,
        appellantDateOfBirth: '1992-08-02',
        appellantAddress: {
          address_line_1: '9999 MISSION ST',
          address_line_2: 'UBER',
          address_line_3: 'APT 2',
          city: 'SAN FRANCISCO',
          zip: '94103',
          country: 'USA',
          state: 'CA'
        },
        appellantEmailAddress: 'Bob.Smithhansen@test.com',
        appellantPhoneNumber: null,
        appellantType: 'VeteranClaimant',
        appellantPartyType: null,
        appellantTz: 'America/Los_Angeles',
        appellantRelationship: 'Veteran',
        hasPOA: {
          id: 352,
          authzn_change_clmant_addrs_ind: null,
          authzn_poa_access_ind: null,
          claimant_participant_id: '500000375',
          created_at: '2022-08-02T11:21:58.947-04:00',
          file_number: '00001234',
          last_synced_at: '2022-08-02T11:21:58.947-04:00',
          legacy_poa_cd: '100',
          poa_participant_id: '600153863',
          representative_name: 'Clarence Darrow',
          representative_type: 'Attorney',
          updated_at: '2022-08-02T11:21:58.947-04:00'
        },
        assignedToLocation: 'VHA CAMO',
        veteranDateOfDeath: null,
        closestRegionalOffice: null,
        closestRegionalOfficeLabel: null,
        availableHearingLocations: [],
        status: 'pre_docketed',
        decisionDate: null,
        nodDate: '2022-08-02',
        nodDateUpdates: [],
        certificationDate: null,
        powerOfAttorney: {
          representative_type: 'Attorney',
          representative_name: 'Clarence Darrow',
          representative_address: {
            address_line_1: '9999 MISSION ST',
            address_line_2: 'UBER',
            address_line_3: 'APT 2',
            city: 'SAN FRANCISCO',
            zip: '94103',
            country: 'USA',
            state: 'CA'
          },
          representative_email_address: 'jamie.fakerton@caseflowdemo.com',
          representative_tz: 'America/Los_Angeles',
          poa_last_synced_at: '2022-08-02T11:21:58.947-04:00'
        },
        cavcRemand: null,
        regionalOffice: null,
        caseflowVeteranId: 376,
        documentID: null,
        caseReviewId: null,
        canEditDocumentId: false,
        attorneyCaseRewriteDetails: {
          note_from_attorney: null,
          untimely_evidence: null
        },
        docketSwitch: null,
        switchedDockets: [],
        appellantSubstitution: null,
        substitutions: [],
        hasSameAppealSubstitution: true,
        remandSourceAppealId: null,
        remandJudgeName: null,
        veteranInfo: {
          veteran: {
            full_name: 'Bob Smithhansen',
            gender: 'F',
            date_of_birth: '08/02/1992',
            date_of_death: null,
            email_address: 'Bob.Smithhansen@test.com',
            address: {
              address_line_1: '1234 Main Street',
              address_line_2: null,
              address_line_3: null,
              city: 'Orlando',
              state: 'FL',
              zip: '12345',
              country: 'USA'
            },
            relationships: null
          }
        }
      }
    }
  },
  ...uiData
};

export const postData = {
  tasks: {
    data: [
      {
        id: '7139',
        type: 'task',
        attributes: {
          is_legacy: false,
          type: 'VhaDocumentSearchTask',
          label: 'Review Documentation',
          appeal_id: 1633,
          status: 'completed',
          assigned_at: '2022-08-08T21:24:56.274-04:00',
          started_at: null,
          created_at: '2022-08-08T21:24:56.274-04:00',
          closed_at: '2022-08-08T21:31:10.797-04:00',
          cancellation_reason: null,
          instructions: [
            'fake instructions'
          ],
          appeal_type: 'Appeal',
          parent_id: 7138,
          timeline_title: 'VhaDocumentSearchTask completed',
          hide_from_queue_table_view: false,
          hide_from_case_timeline: false,
          hide_from_task_snapshot: false,
          assigned_by: {
            first_name: 'Ignacio',
            last_name: 'Shaw',
            full_name: 'Ignacio BvaIntakeUser Shaw',
            css_id: 'BVAISHAW',
            pg_id: 18
          },
          assigned_to: {
            css_id: null,
            full_name: null,
            is_organization: true,
            name: 'VHA CAMO',
            status: 'active',
            type: 'VhaCamo',
            id: 30
          },
          cancelled_by: {
            css_id: null
          },
          converted_by: {
            css_id: null
          },
          converted_on: null,
          assignee_name: 'VHA CAMO',
          placed_on_hold_at: null,
          on_hold_duration: null,
          docket_name: 'direct_review',
          case_type: 'Original',
          docket_number: '220731-1633',
          docket_range_date: null,
          veteran_full_name: 'Bob Smithhahn',
          veteran_file_number: '500000007',
          closest_regional_office: null,
          external_appeal_id: '809c244d-1d8b-4fff-b3c7-a9796d71e4e6',
          aod: false,
          overtime: false,
          contested_claim: false,
          veteran_appellant_deceased: false,
          issue_count: 1,
          external_hearing_id: null,
          available_hearing_locations: [],
          previous_task: {
            assigned_at: null
          },
          document_id: null,
          decision_prepared_by: {
            first_name: null,
            last_name: null
          },
          available_actions: [],
          can_move_on_docket_switch: false,
          timer_ends_at: null,
          unscheduled_hearing_notes: null
        }
      }
    ],
    alerts: []
  }
};

export const camoToProgramOfficeToCamoData = {
  queue: {
    amaTasks: {
      7119: {
        uniqueId: '7119',
        isLegacy: false,
        type: 'VhaDocumentSearchTask',
        appealType: 'Appeal',
        addedByCssId: null,
        appealId: 1632,
        externalAppealId: 'bc7ba6d4-48a7-436b-97e8-62bc061c604e',
        assignedOn: '2022-08-08T22:11:55.277-04:00',
        closestRegionalOffice: null,
        createdAt: '2022-08-02T12:03:32.187-04:00',
        closedAt: null,
        startedAt: null,
        assigneeName: 'VHA CAMO',
        assignedTo: {
          cssId: null,
          name: 'VHA CAMO',
          id: 31,
          isOrganization: true,
          type: 'VhaCamo'
        },
        assignedBy: {
          firstName: 'Ignacio',
          lastName: 'Shaw',
          cssId: 'BVAISHAW',
          pgId: 18
        },
        cancelledBy: {
          cssId: null
        },
        cancelReason: null,
        convertedBy: {
          cssId: null
        },
        convertedOn: null,
        taskId: '7119',
        parentId: 7118,
        label: 'Review Documentation',
        documentId: null,
        externalHearingId: null,
        workProduct: null,
        previousTaskAssignedOn: null,
        placedOnHoldAt: '2022-08-08T22:11:34.349-04:00',
        status: 'assigned',
        instructions: [],
        availableActions: [
          {
            func: 'vha_assign_to_program_office_data',
            label: 'Assign to Program Office',
            value: 'modal/assign_to_program_office',
            data: {
              options: [
                {
                  label: 'Community Care - Payment Operations Management',
                  value: 33
                },
                {
                  label: 'Community Care - Veteran and Family Members Program',
                  value: 34
                },
                {
                  label: 'Member Services - Health Eligibility Center',
                  value: 35
                },
                {
                  label: 'Member Services - Beneficiary Travel',
                  value: 36
                },
                {
                  label: 'Prosthetics',
                  value: 37
                }
              ],
              modal_title: 'Assign to Program Office',
              modal_body: 'Provide instructions and context for this action:',
              modal_selector_placeholder: 'Select Program Office',
              type: 'AssessDocumentationTask',
              redirect_after: '/organizations/vha-camo'
            }
          },
          {
            func: 'vha_send_to_board_intake',
            label: 'Send to Board Intake',
            value: 'modal/vha_send_to_board_intake',
            data: {
              modal_title: 'Send to Board Intake',
              type: 'VhaDocumentSearchTask',
              redirect_after: '/organizations/vha-camo'
            }
          }
        ],
        timelineTitle: 'VhaDocumentSearchTask completed'
      },
      7962: {
        uniqueId: '7962',
        isLegacy: false,
        type: 'AssessDocumentationTask',
        appealType: 'Appeal',
        appealId: 1632,
        externalAppealId: 'bc7ba6d4-48a7-436b-97e8-62bc061c604e',
        assignedOn: '2022-08-08T22:11:34.279-04:00',
        closestRegionalOffice: null,
        createdAt: '2022-08-08T22:11:34.279-04:00',
        closedAt: '2022-08-08T22:11:55.204-04:00',
        startedAt: null,
        status: 'completed',
        assigneeName: 'Prosthetics',
        assignedTo: {
          cssId: null,
          name: 'Prosthetics',
          id: 37,
          isOrganization: true,
          type: 'VhaProgramOffice'
        },
        taskId: '7962',
        parentId: 7119,
        label: 'Assess Documentation',
        instructions: [
          'CAMO to PO',
          'Documents for this appeal are stored in VBMS.\n\n**Detail:**\n\n PO back to CAMO!\n'
        ],
        timelineTitle: 'AssessDocumentationTask completed',
      }
    },
    appeals: {
      'bc7ba6d4-48a7-436b-97e8-62bc061c604e': {
        id: '1632',
        appellant_hearing_email_recipient: null,
        representative_hearing_email_recipient: null,
        externalId: 'bc7ba6d4-48a7-436b-97e8-62bc061c604e',
        docketName: 'direct_review',
        withdrawn: false,
        removed: false,
        overtime: false,
        contestedClaim: false,
        veteranAppellantDeceased: false,
        isLegacyAppeal: false,
        caseType: 'Original',
        isAdvancedOnDocket: false,
        issueCount: 1,
        docketNumber: '220731-1632',
        assignedAttorney: null,
        assignedJudge: null,
        distributedToJudge: false,
        veteranFullName: 'Bob Smithframi',
        veteranFileNumber: '500000009',
        isPaperCase: false,
        readableHearingRequestType: null,
        readableOriginalHearingRequestType: null,
        vacateType: null,
        hearings: [],
        currentUserEmail: null,
        currentUserTimezone: 'America/New_York',
        completedHearingOnPreviousAppeal: false,
        issues: [
          {
            id: 3080,
            program: 'vha',
            description: 'Caregiver | Tier Level - Caregiver Queue Test',
            notes: null,
            diagnostic_code: null,
            remand_reasons: [],
            closed_status: null,
            decision_date: '2022-07-31'
          }
        ],
        decisionIssues: [],
        canEditRequestIssues: false,
        unrecognizedAppellantId: null,
        appellantIsNotVeteran: false,
        appellantFullName: 'Bob Smithframi',
        appellantFirstName: 'Bob',
        appellantMiddleName: null,
        appellantLastName: 'Smithframi',
        appellantSuffix: null,
        appellantDateOfBirth: '1992-08-02',
        appellantAddress: {
          address_line_1: '9999 MISSION ST',
          address_line_2: 'UBER',
          address_line_3: 'APT 2',
          city: 'SAN FRANCISCO',
          zip: '94103',
          country: 'USA',
          state: 'CA'
        },
        appellantEmailAddress: 'Bob.Smithframi@test.com',
        appellantPhoneNumber: null,
        appellantType: 'VeteranClaimant',
        appellantPartyType: null,
        appellantTz: 'America/Los_Angeles',
        appellantRelationship: 'Veteran',
        hasPOA: {
          id: 1490,
          authzn_change_clmant_addrs_ind: null,
          authzn_poa_access_ind: null,
          claimant_participant_id: '500000009',
          created_at: '2022-08-02T12:02:34.112-04:00',
          file_number: '00001234',
          last_synced_at: '2022-08-02T12:02:34.112-04:00',
          legacy_poa_cd: '100',
          poa_participant_id: '600153863',
          representative_name: 'Clarence Darrow',
          representative_type: 'Attorney',
          updated_at: '2022-08-02T12:02:34.112-04:00'
        },
        assignedToLocation: 'VHA CAMO',
        veteranDateOfDeath: null,
        closestRegionalOffice: null,
        closestRegionalOfficeLabel: null,
        availableHearingLocations: [],
        status: 'pre_docketed',
        decisionDate: null,
        nodDate: '2022-07-31',
        nodDateUpdates: [],
        certificationDate: null,
        powerOfAttorney: {
          representative_type: 'Attorney',
          representative_name: 'Clarence Darrow',
          representative_address: {
            address_line_1: '9999 MISSION ST',
            address_line_2: 'UBER',
            address_line_3: 'APT 2',
            city: 'SAN FRANCISCO',
            zip: '94103',
            country: 'USA',
            state: 'CA'
          },
          representative_email_address: 'jamie.fakerton@caseflowdemo.com',
          representative_tz: 'America/Los_Angeles',
          poa_last_synced_at: '2022-08-02T12:02:34.112-04:00'
        },
        cavcRemand: null,
        regionalOffice: null,
        caseflowVeteranId: 10,
        documentID: null,
        caseReviewId: null,
        canEditDocumentId: false,
        attorneyCaseRewriteDetails: {
          note_from_attorney: null,
          untimely_evidence: null
        },
        docketSwitch: null,
        switchedDockets: [],
        appellantSubstitution: null,
        substitutions: [],
        hasSameAppealSubstitution: true,
        remandSourceAppealId: null,
        remandJudgeName: null,
        veteranInfo: {
          veteran: {
            full_name: 'Bob Smithframi',
            gender: 'F',
            date_of_birth: '08/02/1992',
            date_of_death: null,
            email_address: 'Bob.Smithframi@test.com',
            address: {
              address_line_1: '1234 Main Street',
              address_line_2: null,
              address_line_3: null,
              city: 'Orlando',
              state: 'FL',
              zip: '12345',
              country: 'USA'
            },
            relationships: null
          }
        }
      }
    }
  },
  ...uiData
};
/* eslint-enable max-lines */
