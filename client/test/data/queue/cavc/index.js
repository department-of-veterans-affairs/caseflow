import { add, format, sub } from 'date-fns';

export const decisionIssues = [
  { id: 1, description: 'Tinnitus, Left Ear' },
  { id: 2, description: 'Right Knee' },
  { id: 3, description: 'Right Knee' },
];

export const existingValues = {
  docketNumber: '12-3456',
  attorney: 'no',
  judge: 'Panel',
  decisionType: 'remand',
  remandType: 'jmr',
  decisionDate: format(sub(new Date(), { days: 7 }), 'yyyy-MM-dd'),
  issueIds: [2, 3],
  instructions: 'Lorem ipsum dolor sit amet',
};

export const remandDatesProvided = {
  ...existingValues,
  decisionType: 'straight_reversal',
  remandType: null,
  remandDatesProvided: 'yes',
  decisionDate: format(add(new Date(), { days: 7 }), 'yyyy-MM-dd'),
  judgementDate: format(new Date(), 'yyyy-MM-dd'),
  mandateDate: format(new Date(), 'yyyy-MM-dd'),
};

export const supportedDecisionTypes = [
  'remand',
  'straight_reversal',
  'death_dismissal',
];
export const supportedRemandTypes = ['jmr', 'jmpr', 'mdr'];

export const nodDate = '2022-04-29T10:33:06.895-04:00';
export const dateOfDeath = '2021-04-29T10:33:06.895-04:00';
export const featureToggles = {
  cavc_remand_granted_substitute_appellant: false
};
