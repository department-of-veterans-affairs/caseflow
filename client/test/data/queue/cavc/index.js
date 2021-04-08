import { format, sub } from 'date-fns';

export const existingValues = {
  docketNumber: '12-3456',
  attorney: 'no',
  judge: 'Panel',
  decisionType: 'remand',
  remandType: 'mdr',
  decisionDate: format(sub(new Date(), { days: 7 }), 'yyyy-MM-dd'),
  issueIds: [2, 3],
  instructions: 'Lorem ipsum dolor sit amet',
};

export const decisionIssues = [
  { id: 1, description: 'Tinnitus, Left Ear' },
  { id: 2, description: 'Right Knee' },
  { id: 3, description: 'Right Knee' },
];

export const supportedDecisionTypes = [
  'remand',
  'straight_reversal',
  'death_dismissal',
];
export const supportedRemandTypes = ['jmr', 'jmpr', 'mdr'];

export const existingValuesJmr = {
  docketNumber: '12-345678',
  attorney: 'yes',
  judge: 'Clerk',
  decisionType: 'remand',
  remandType: 'jmr',
  decisionDate: format(sub(new Date(), { days: 7 }), 'yyyy-MM-dd'),
  judgementDate: format(sub(new Date(), { days: 6 }), 'yyyy-MM-dd'),
  mandateDate: format(sub(new Date(), { days: 6 }), 'yyyy-MM-dd'),
  issueIds: [1, 2, 3],
  instructions: 'Lorem ipsum dolor sit amet',
};
