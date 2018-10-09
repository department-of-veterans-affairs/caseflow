import INTAKE_FORM_NAMES from '../../constants/INTAKE_FORM_NAMES.json';

export const FORM_TYPES = {
  RAMP_ELECTION: {
    key: 'ramp_election',
    name: INTAKE_FORM_NAMES.ramp_election,
    category: 'ramp'
  },
  RAMP_REFILING: {
    key: 'ramp_refiling',
    name: INTAKE_FORM_NAMES.ramp_refiling,
    category: 'ramp'
  },
  HIGHER_LEVEL_REVIEW: {
    key: 'higher_level_review',
    name: INTAKE_FORM_NAMES.higher_level_review,
    category: 'ama'
  },
  SUPPLEMENTAL_CLAIM: {
    key: 'supplemental_claim',
    name: INTAKE_FORM_NAMES.supplemental_claim,
    category: 'ama'
  },
  APPEAL: {
    key: 'appeal',
    name: INTAKE_FORM_NAMES.appeal,
    category: 'ama'
  }
};

const issueCategoriesArray = [
  'Unknown issue category',
  'Apportionment',
  'Incarceration Adjustments',
  'Audit Error Worksheet (DFAS)',
  'Active Duty Adjustments',
  'Drill Pay Adjustments',
  'Character of discharge determinations',
  'Income/net worth (pension)',
  'Dependent child - Adopted',
  'Dependent child - Stepchild',
  'Dependent child - Biological',
  'Dependency Spouse - Common law marriage',
  'Dependency Spouse - Inference of marriage',
  'Dependency Spouse - Deemed valid marriage',
  'Military Retired Pay',
  'Contested Claims (other than apportionment)',
  'Lack of Qualifying Service',
  'Other non-rated'
];

export const ISSUE_CATEGORIES = issueCategoriesArray.map((category) => {
  return {
    value: category,
    label: category
  };
});

export const REQUEST_STATE = {
  NOT_STARTED: 'NOT_STARTED',
  IN_PROGRESS: 'IN_PROGRESS',
  SUCCEEDED: 'SUCCEEDED',
  FAILED: 'FAILED'
};
