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

const vhaDocumentSearchTaskData = {
  7119: {
    uniqueId: '7119',
    isLegacy: false,
    type: 'VhaDocumentSearchTask',
    appealType: 'Appeal',
    addedByCssId: null,
    appealId: 1632,
    externalAppealId: '419ce568-387c-4ac6-a5f5-00a1554cea36',
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
  }
};

export const camoToBvaIntakeData = {
  queue: {
    amaTasks: {
      ...vhaDocumentSearchTaskData
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36'
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
          previous_task: {
            assigned_at: null
          },
        }
      }
    ],
    alerts: []
  }
};

export const camoToProgramOfficeToCamoData = {
  queue: {
    amaTasks: {
      ...vhaDocumentSearchTaskData,
      7962: {
        uniqueId: '7962',
        isLegacy: false,
        type: 'AssessDocumentationTask',
        appealType: 'Appeal',
        appealId: 1632,
        externalAppealId: '419ce568-387c-4ac6-a5f5-00a1554cea36',
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
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36'
      }
    }
  },
  ...uiData
};
