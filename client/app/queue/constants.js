/* eslint-disable max-lines */
import { css } from 'glamor';

export const COLORS = {
  QUEUE_LOGO_PRIMARY: '#11598D',
  QUEUE_LOGO_OVERLAP: '#0E456C',
  QUEUE_LOGO_BACKGROUND: '#D6D7D9',
  // $color-secondary-dark in uswds/core/_variables.scss
  ERROR: '#CD2026'
};

export const ACTIONS = {
  RECEIVE_QUEUE_DETAILS: 'RECEIVE_QUEUE_DETAILS',
  RECEIVE_JUDGE_DETAILS: 'RECEIVE_JUDGE_DETAILS',
  SET_LOADED_QUEUE_ID: 'SET_LOADED_QUEUE_ID',
  SET_APPEAL_DOC_COUNT: 'SET_APPEAL_DOC_COUNT',
  LOAD_APPEAL_DOC_COUNT_FAILURE: 'LOAD_APPEAL_DOC_COUNT_FAILURE',
  SET_REVIEW_ACTION_TYPE: 'SET_REVIEW_ACTION_TYPE',
  SET_DECISION_OPTIONS: 'SET_DECISION_OPTIONS',
  RESET_DECISION_OPTIONS: 'RESET_DECISION_OPTIONS',
  START_EDITING_APPEAL: 'START_EDITING_APPEAL',
  CANCEL_EDITING_APPEAL: 'CANCEL_EDITING_APPEAL',
  START_EDITING_APPEAL_ISSUE: 'START_EDITING_APPEAL_ISSUE',
  CANCEL_EDITING_APPEAL_ISSUE: 'CANCEL_EDITING_APPEAL_ISSUE',
  SAVE_EDITED_APPEAL_ISSUE: 'SAVE_EDITED_APPEAL_ISSUE',
  UPDATE_APPEAL_ISSUE: 'UPDATE_APPEAL_ISSUE'
};

// 'red' isn't contrasty enough w/white; it raises Sniffybara::PageNotAccessibleError when testing
export const redText = css({ color: '#E60000' });
export const boldText = css({ fontWeight: 'bold' });
export const fullWidth = css({ width: '100%' });

export const CATEGORIES = {
  QUEUE_TABLE: 'Queue Table',
  QUEUE_TASK: 'Queue Task'
};

export const TASK_ACTIONS = {
  VIEW_APPELLANT_INFO: 'view-appellant-info',
  VIEW_APPEAL_INFO: 'view-appeal-info',
  QUEUE_TO_READER: 'queue-to-reader'
};

export const ERROR_FIELD_REQUIRED = 'This field is required';

export const DECISION_TYPES = {
  OMO_REQUEST: 'OMORequest',
  DRAFT_DECISION: 'DraftDecision'
};

/*
{
  `issprog`: {
    description: `Program Description`,
    issue: {
      `isscode`: {
        description: `Issue Description,
        levels: {
          `isslev1`: {
            description: `Level 1 Description,
            levels: {
              `isslev2`: {
                description: `Level 2 Description`,
                levels: {
                  `isslev3`: {
                    todo: Diagnostic codes?
                    description: `Level 3 Description`
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
 */
export const ISSUE_INFO = {
  '01': {
    description: 'VBA Burial',
    issue: {
      '01': {
        description: 'Entitlement',
        levels: {
          '01': { description: 'Service connected' },
          '02': { description: 'Nonservice connected' }
        }
      },
      '02': {
        description: 'Other'
      }
    }
  },
  '02': {
    description: 'Compensation',
    issue: {
      '01': {
        description: '1151 Eligibility',
        levels: {
          '01': { description: 'Accrued ' },
          '02': { description: 'Other' }
        }
      },
      '02': { description: 'Apportionment' },
      '03': {
        description: 'Automobile or adaptive equipment',
        levels: {
          '01': { description: 'Eligibility' },
          '02': { description: 'Other' }
        }
      },
      '04': {
        description: 'Civil Service preference',
        levels: {
          '01': { description: 'Eligibility' }
        }
      },
      '05': {
        description: 'Clothing allowance',
        levels: {
          '01': { description: 'Eligibility' },
          '02': { description: 'Other' },
          '03': { description: 'Timeliness of filing' }
        }
      },
      '06': { description: 'Competency of payee' },
      '07': {
        description: 'CUE (38 C.F.R. 3.105)',
        levels: {
          '01': { description: 'Accrued' },
          '02': { description: 'DIC' },
          '03': { description: 'Effective date' },
          '04': { description: 'Rating increase or decrease' },
          '05': { description: 'Service connection grant or severance' },
          '06': { description: 'TDIU grant or termination' },
          '07': { description: 'Temporary total grant or termination' },
          '08': { description: 'Other' }
        }
      },
      '08': {
        description: 'DIC',
        levels: {
          '01': { description: '38 U.S.C. 1318' },
          '02': { description: 'Contested claim' },
          '03': { description: 'SC cause of death' },
          '04': { description: 'Status as claimant' },
          '05': { description: 'Other' }
        }
      },
      '09': {
        description: 'Effective date',
        levels: {
          '01': { description: 'Accrued' },
          '02': { description: 'DIC' },
          '03': { description: 'Rating increase or decrease' },
          '04': { description: 'Service connection grant or severance' },
          '05': { description: 'TDIU grant or termination' },
          '06': { description: 'Temporary total grant or termination' },
          '07': { description: 'Other' }
        }
      },
      10: { description: 'Forfeiture of benefits' },
      11: {
        description: 'Increased rate for dependents',
        levels: {
          '01': { description: 'Accrued' },
          '02': { description: 'Adoption' },
          '03': { description: 'Helpless child' },
          '04': { description: 'Paternity' },
          '05': { description: 'Stepchild' },
          '06': { description: 'Validity of marriage' },
          '07': { description: 'Other' }
        }
      },
      12: {
        description: 'Increased rating',
        levels: {
          '01': { description: '10% under 38 C.F.R. 3.324' },
          '02': { description: 'Accrued' },
          '03': { description: 'Extraschedular' },
          '04': { description: 'Schedular' },
          '05': { description: 'SMC' },
          '06': { description: 'Temporary total' },
          '07': { description: 'Other' },
          '08': { description: 'Schedular & Extraschedular' }
        }
      },
      13: {
        description: 'Overpayment',
        levels: {
          '01': { description: 'Validity of debt' },
          '02': { description: 'Waiver' }
        }
      },
      14: {
        description: 'Severance of service connection',
        levels: {
          '01': { description: 'Accrued' },
          '02': { description: 'Dental' },
          '03': { description: 'All others' }
        }
      },
      15: {
        description: 'Service connection',
        levels: {
          '01': { description: 'Accrued' },
          '02': { description: 'Dental' },
          '03': { description: 'All Others' },
          '04': { description: 'New and Material' }
        }
      },
      16: {
        description: 'Status as a veteran',
        levels: {
          '01': { description: 'Character of discharge' },
          '02': { description: 'Recognized service' },
          '03': { description: 'Other' }
        }
      },
      17: {
        description: 'TDIU',
        levels: {
          '01': { description: 'Accrued' },
          '02': { description: 'Entitlement' },
          '03': { description: 'Termination' }
        }
      },
      18: {
        description: 'Reductions',
        levels: {
          '01': {
            description: 'Rating reductions',
            levels: {
              '01': { description: 'Accrued' },
              '02': { description: 'Extraschedular' },
              '03': { description: 'Protection' },
              '04': { description: 'Schedular' },
              '05': { description: 'SMC' },
              '06': { description: 'Temporary total' },
              '07': { description: 'Other' }
            }
          },
          '02': {
            description: 'Nonrating reductions',
            levels: {
              '01': { description: 'Incarcerated payee' },
              '02': { description: 'Institutionalized payee' },
              '03': { description: 'Removal of dependent' },
              '04': { description: 'Recoupment' },
              '05': { description: 'Other' }
            }
          }
        }
      },
      19: {
        description: 'Specially adapted housing',
        levels: {
          '01': { description: 'Eligibility ' },
          '02': { description: 'Other' }
        }
      },
      20: {
        // todo: description cut off in doc
        description: 'Survivors & dependents educational assistance (Cha',
        levels: {
          '01': { description: 'Accrued' },
          '02': { description: 'Eligibility' },
          '03': { description: 'Other' }
        }
      },
      21: { description: 'Willfull misconduct/LOD' },
      22: { description: 'Eligibility for Substitution' }
    }
  },
  '03': {
    description: 'Education',
    issue: {
      '01': { description: 'Accrued' },
      '02': {
        description: 'Eligibility',
        levels: {
          '01': { description: '38 U.S.C. ch. 30' },
          '02': { description: '38 U.S.C. ch. 35' },
          '03': { description: '38 U.S.C. ch. 32' },
          '04': { description: 'Ed. Assist. Test Program' }
        }
      },
      '03': {
        description: 'Effective Date of Award',
        levels: {
          '01': { description: '38 U.S.C ch.30' },
          '02': { description: '10 U.S.C. ch. 1606' },
          '03': { description: '38 U.S.C. ch. 35' },
          '04': { description: '38 U.S.C. ch. 32' },
          '05': { description: 'Ed. Assist. Test Program' }
        }
      },
      '04': {
        description: 'Extension of Delimiting Date',
        levels: {
          '01': { description: '38 U.S.C. ch. 30' },
          '02': { description: '10 U.S.C. ch. 1606' },
          '03': { description: '38 U.S.C. ch. 35' },
          '04': { description: '38 U.S.C. ch. 32' }
        }
      },
      '05': {
        description: 'Overpayment',
        levels: {
          '01': { description: 'Validity of debt' },
          '02': { description: 'Waiver' }
        }
      },
      '06': { description: 'Other' }
    }
  },
  '04': {
    description: 'Insurance',
    issue: {
      '01': {
        description: 'Waiver of premiums (1912-1914)',
        levels: {
          '01': { description: 'Date of total disability' },
          '02': { description: 'Effective date' },
          '03': { description: 'TDIP (1915)' },
          '04': { description: 'Other' }
        }
      },
      '02': {
        description: 'Reinstatement',
        levels: {
          '01': { description: 'Medically qualified' },
          '02': { description: 'Other' }
        }
      },
      '03': {
        description: 'RH (1922(a) S-DVI)',
        levels: {
          '01': { description: 'Timely application' },
          '02': { description: 'Medically qualified' },
          '03': { description: 'Discharged before 4/25/51' },
          '04': { description: 'Other' }
        }
      },
      '04': {
        description: 'SRH (1922(b) S-DVI)',
        levels: {
          '01': { description: 'Timely application' },
          '02': { description: 'Over age 65' },
          '03': { description: 'Other' }
        }
      },
      '05': {
        description: 'Contested death claim',
        levels: {
          '01': { description: 'Relationships' },
          '02': { description: 'Testamentary capacity' },
          '03': { description: 'Undue influence' },
          '04': { description: 'Intent of insured' },
          '05': { description: 'Other' }
        }
      },
      '06': { description: 'Other' }
    }
  },
  '05': {
    description: 'Loan Guaranty',
    issue: {
      '01': { description: 'Basic eligibility' },
      '02': { description: 'Validity of debt' },
      '03': { description: 'Waiver of indebtedness' },
      '04': { description: 'Retroactive release of liability' },
      '05': { description: 'Restoration of entitlement' },
      '06': { description: 'Other' }
    }
  },
  '06': {
    description: 'Medical',
    issue: {
      '01': {
        description: 'Eligibility for treatment',
        levels: {
          '01': { description: 'Dental' },
          '02': { description: 'Other' }
        }
      },
      '02': { description: 'Medical expense reimbursement' },
      '03': { description: 'Eligibility for fee basis care' },
      '04': {
        description: 'Indebtedness',
        levels: {
          '01': { description: 'Validity of Debt' },
          '02': { description: 'Waiver' }
        }
      },
      '05': { description: 'Level of priority for treatment' },
      '06': { description: 'Other' },
      '07': { description: 'Clothing allowance § 3.810(b) certification' }
    }
  },
  '07': {
    description: 'Pension',
    issue: {
      '01': { description: 'Accrued benefits' },
      '02': { description: 'Apportionment' },
      '03': { description: 'Countable income' },
      '04': { description: 'CUE (38 C.F.R. 3.105)' },
      '05': { description: 'Death pension' },
      '06': { description: 'Effective date' },
      '07': {
        description: 'Eligibility',
        levels: {
          '01': { description: 'Wartime service' },
          '02': { description: 'Unemployability' },
          '03': { description: 'Recognized service' }
        }
      },
      '08': {
        description: 'Increased rate for dependents',
        levels: {
          '01': { description: 'Adoption' },
          '02': { description: 'Helpless child' },
          '03': { description: 'Paternity' },
          '04': { description: 'Stepchild' },
          '05': { description: 'Validity of marriage' },
          '06': { description: 'Other' }
        }
      },
      '09': { description: 'SMP' },
      10: {
        description: 'Overpayment',
        levels: {
          '01': { description: 'Validity of debt' },
          '02': { description: 'Waiver' }
        }
      },
      11: { description: 'Willful misconduct/LOD' },
      12: { description: 'Other' }
    }
  },
  '08': {
    description: 'VRE',
    issue: {
      '01': { description: 'Basic Eligibility' },
      '02': { description: 'Entitlement to Services' },
      '03': { description: 'Plan/Goal Selection' },
      '04': { description: 'Equipment Purchases' },
      '05': { description: 'Additional Training' },
      '06': { description: 'Change of Program' },
      '07': { description: 'Other' }
    }
  },
  '09': {
    description: 'Other',
    issue: {
      '01': {
        description: 'Attorney fees',
        levels: {
          '01': { description: 'Failure to withhold fees' },
          '02': { description: 'Eligibility for direct fee payment' }
        }
      },
      '02': {
        description: 'REPS',
        levels: {
          '01': { description: 'Basic Eligibility' },
          '02': { description: 'Relationship' },
          '03': { description: 'Full-time school attendance' },
          '04': { description: 'Income/self-employment' },
          '05': {
            description: 'Indebtedness',
            levels: {
              '01': { description: 'Validity of debt' },
              '02': { description: 'Waiver' }
            }
          }
        }
      },
      '03': {
        description: 'Spina bifida',
        levels: {
          '01': { description: 'Effective date' },
          '02': { description: 'Eligibility' },
          '03': { description: 'Level of disability' },
          '04': { description: 'Other' }
        }
      },
      '04': { description: 'Waiver of VA employee indebtedness' },
      '05': { description: 'Death Gratuity Certification (38 USC 1323)' },
      // todo: '06'?
      '07': { description: 'VBMS Access' }
    }
  },
  10: {
    description: 'BVA',
    issue: {
      '01': {
        description: 'Attorney fees/expenses',
        levels: {
          '01': { description: 'Payment from past-due benefits' },
          '02': { description: 'Reasonableness' }
        }
      },
      '02': {
        description: 'CUE under 38 U.S.C. 7111',
        levels: {
          '01': { description: 'Compensation' },
          '02': { description: 'Pension' },
          '03': { description: 'Other' }
        }
      },
      '03': {
        description: 'Motions',
        levels: {
          '01': { description: 'Rule 608 motion to withdraw' },
          '02': { description: 'Rule 702, 704, or 717 motion for new hearing date' },
          '03': { description: 'Rule 711 motion to issue or quash subpoena' },
          '04': { description: 'Rule 716 motion for correction of hearing transcription' },
          '05': { description: 'Rule 900 motion to advance on docket' },
          '06': { description: 'Rule 904 motion to vacate' },
          '07': { description: 'Rule 1001 motion for consideration' },
          '08': {
            description: 'Rule 1304(b) motion',
            levels: {
              '01': { description: 'Evidence submission' },
              '02': { description: 'Hearing request' },
              '03': { description: 'Request to change representative' }
            }
          }
        }
      },
      '04': { description: 'Designation of record' }
    }
  },
  11: {
    description: 'NCA Burial',
    issue: {
      '01': {
        description: 'Entitlement',
        levels: {
          '01': { description: 'Reserves/National Guard' },
          '02': { description: 'Less than 24 months' },
          '03': { description: 'Character of service' },
          '04': { description: 'Merchant Marine' },
          '05': { description: 'No military information' },
          '06': { description: 'Cadet (service academies)' },
          '07': { description: 'Adult child with waiver request' },
          '08': { description: 'Allied forces and non-citizens' },
          '09': { description: 'Pre-need' },
          10: { description: 'Spouse or dependent' },
          11: { description: 'Non-qualifying service' },
          12: { description: 'ABMC/overseas burial' },
          13: { description: 'Pre-WWI/burial site unknown' },
          14: { description: 'Marked grave (death prior to 10-18-78)' },
          15: { description: 'Marked grave (death on/after 10-18-78 to 10-31-90)' }
        }
      },
      '02': { description: 'Other' }
    }
  },
  12: {
    description: 'Fiduciary',
    issue: {
      '01': {
        description: 'Fiduciary Appointment'
      }
    }
  },
  13: {
    description: 'Test Levels',
    issue: {
      '01': { description: 'Issue, no sublevels' },
      '02': {
        description: 'Issue, 1 sublevel',
        levels: {
          '01': { description: 'First Level, no sublevels' },
          '02': { description: 'First level 2, no sublevels' }
        }
      },
      '03': {
        description: 'Issue, 2 sublevels',
        levels: {
          '01': {
            description: 'First Level, sublevels',
            levels: {
              '01': { description: 'Second Level 1' },
              '02': { description: 'Second Level 2'}
            }
          }
        }
      },
      '04': {
        description: 'Issue, 3 sublevels',
        levels: {
          '01': {
            description: 'First level, all sublevels',
            levels: {
              '01': {
                description: 'Second level 1',
                levels: {
                  '01': { description: 'Third level 1' },
                  '02': { description: 'Third level 2' }
                }
              }
            }
          }
        }
      }
    }
  }
};
