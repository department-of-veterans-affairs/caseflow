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
  UPDATE_APPEAL_ISSUE: 'UPDATE_APPEAL_ISSUE',
  SET_SELECTING_JUDGE: 'SET_SELECTING_JUDGE',
  PUSH_BREADCRUMB: 'PUSH_BREADCRUMB',
  RESET_BREADCRUMBS: 'RESET_BREADCRUMBS',
  HIGHLIGHT_INVALID_FORM_ITEMS: 'HIGHLIGHT_INVALID_FORM_ITEMS'
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

export const ISSUE_PROGRAMS = {
  '01': 'VBA Burial',
  '02': 'Compensation',
  '03': 'Education',
  '04': 'Insurance',
  '05': 'Loan Guaranty',
  '06': 'Medical',
  '07': 'Pension',
  '08': 'VRE', // todo: VR&C?
  '09': 'Other',
  '10': 'BVA',
  '11': 'NCA Burial',
  '12': 'Fiduciary',
};

export const ISSUE_DESCRIPTIONS_LEVELS = {
  '01': {
    '01': 'Entitlement',
    '02': 'Other'
  },
  '02': {
    '01': '1151 Eligibility',
    '02': 'Apportionment',
    '03': 'Automobile or adaptive equipment',
    '04': 'Civil Service preference',
    '05': 'Clothing allowance',
    '06': 'Competency of payee',
    '07': 'CUE (38 C.F.R. 3.105)',
    '08': 'DIC',
    '09': 'Effective Date',
    '10': 'Forefeiture of benefits',
    '11': 'Increased rate for dependents',
    '12': 'Increased rating',
    '13': 'Overpayment',
    '14': 'Severance of service connection',
    '15': 'Service connection',
    '16': 'Status as a veteran',
    '17': 'TDIU',
    '18': 'Reductions',
    '19': 'Specially adapted housing',
    '20': 'Survivors & dependents educational assistance (Cha', // todo: cut off in doc
    '21': 'Willfull misconduct/LOD',
    '22': 'Eligibility for Substitution'
  },
  '03': {
    '01': 'Accrued',
    '02': 'Eligibility',
    '03': 'Effective Date of Award',
    '04': 'Extension of Delimiting Date',
    '05': 'Overpayment',
    '06': 'Other'
  },
  '04': {
    '01': 'Waiver of premiums (1912-1914)',
    '02': 'Reinstatement',
    '03': 'RH (1922(a) S-DVI)',
    '04': 'SRH (1922(b) S-DVI)',
    '05': 'Contested death claim',
    '06': 'Other'
  },
  '05': {
    '01': 'Basic eligibility',
    '02': 'Validity of debt',
    '03': 'Waiver of indebtedness',
    '04': 'Retroactive release of liability',
    '05': 'Restoration of entitlement',
    '06': 'Other'
  },
  '06': {
    '01': 'Eligibility for treatment',
    '02': 'Medical expense reimbursement',
    '03': 'Eligibility for fee basis care',
    '04': 'Indebtedness',
    '05': 'Level of priority for treatment',
    '06': 'Other',
    '07': 'Clothing allowance § 3.810(b) certification',
  },
  '07': {
    '01': 'Accrued benefits',
    '02': 'Apportionment',
    '03': 'Countable income',
    '04': 'CUE (38 C.F.R. 3.105)',
    '05': 'Death pension',
    '06': 'Effective date',
    '07': 'Eligibility',
    '08': 'Increased rate for dependents',
    '09': 'SMP',
    '10': 'Overpayment',
    '11': 'Willful misconduct/LOD',
    '12': 'Other'
  },
  '08': {
    '01': 'Basic Eligibility',
    '02': 'Entitlement to Services',
    '03': 'Plan/Goal Selection',
    '04': 'Equipment Purchases',
    '05': 'Additional Training',
    '06': 'Change of Program',
    '07': 'Other'
  },
  '09': {
    '01': 'Attorney fees',
    '02': 'REPS',
    '03': 'Spina bifida',
    '04': 'Waiver of VA employee indebtedness',
    '05': 'Death Gratuity Certification (38 USC 1323)'
  },
  '10': {
    '01': 'Attorney fees/expenses',
    '02': 'CUE under 38 U.S.C. 7111',
    '03': 'Motions',
    '04': 'Designation of record'
  },
  '11': {
    '01': 'Entitlement',
    '02': 'Other'
  },
  '12': {
    '01': 'Fiduciary Appointment'
  }
}
