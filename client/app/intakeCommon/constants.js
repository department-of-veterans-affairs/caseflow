export const FORM_TYPES = {
  RAMP_ELECTION: {
    key: 'ramp_election',
    name: 'RAMP Opt-In Election Form',
    category: 'ramp'
  },
  RAMP_REFILING: {
    key: 'ramp_refiling',
    name: 'RAMP Selection (VA Form 21-4138)',
    category: 'ramp'
  },
  HIGHER_LEVEL_REVIEW: {
    key: 'higher_level_review',
    name: 'Request for Higher-Level Review (VA Form 20-0988)',
    category: 'ama'
  },
  SUPPLEMENTAL_CLAIM: {
    key: 'supplemental_claim',
    name: 'Supplemental Claim (VA Form 21-526b)',
    category: 'ama'
  },
  APPEAL: {
    key: 'appeal',
    name: 'Notice of Disagreement (VA Form 10182)',
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
