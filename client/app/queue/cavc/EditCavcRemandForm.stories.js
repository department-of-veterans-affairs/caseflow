import React from 'react';
import { format, sub } from 'date-fns';

import { EditCavcRemandForm } from './EditCavcRemandForm';

const decisionIssues = [
  { id: 1, description: 'Tinnitus, Left Ear' },
  { id: 2, description: 'Right Knee' },
  { id: 3, description: 'Right Knee' },
];

export default {
  title: 'Queue/CAVC/EditCavcRemandForm',
  component: EditCavcRemandForm,
  parameters: { controls: { expanded: true } },
  args: {
    decisionIssues,
    supportedDecisionTypes: ['remand', 'straight_reversal', 'death_dismissal'],
    supportedRemandTypes: ['jmr', 'jmpr', 'mdr'],
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <EditCavcRemandForm {...args} />;

export const Default = Template.bind({});

export const EditingRemand = Template.bind({});
EditingRemand.storyName = 'Editing (Remand)';
EditingRemand.args = {
  existingValues: {
    docketNumber: '12-3333',
    attorney: 'yes',
    judge: 'Panel',
    decisionType: 'remand',
    remandType: 'mdr',
    decisionDate: format(sub(new Date(), { days: 7 }), 'yyyy-MM-dd'),
    issueIds: [2, 3],
    instructions: 'Lorem ipsum dolor sit amet'
  },
};

export const EditingReversal = Template.bind({});
EditingReversal.storyName = 'Editing (Reversal)';
EditingReversal.args = {
  existingValues: {
    docketNumber: '12-3333',
    attorney: 'yes',
    judge: 'Panel',
    decisionType: 'straight_reversal',
    remandType: null,
    remandDatesProvided: 'yes',
    decisionDate: format(sub(new Date(), { days: 7 }), 'yyyy-MM-dd'),
    judgementDate: format(sub(new Date(), { days: 5 }), 'yyyy-MM-dd'),
    mandateDate: format(sub(new Date(), { days: 5 }), 'yyyy-MM-dd'),
    issueIds: [2, 3],
    instructions: 'Lorem ipsum dolor sit amet'
  },
};

export const EditingDismissal = Template.bind({});
EditingDismissal.storyName = 'Editing (Dismissal)';
EditingDismissal.args = {
  existingValues: {
    docketNumber: '12-3333',
    attorney: 'yes',
    judge: 'Panel',
    decisionType: 'death_dismissal',
    remandType: null,
    remandDatesProvided: 'yes',
    decisionDate: format(sub(new Date(), { days: 7 }), 'yyyy-MM-dd'),
    judgementDate: format(sub(new Date(), { days: 5 }), 'yyyy-MM-dd'),
    mandateDate: format(sub(new Date(), { days: 5 }), 'yyyy-MM-dd'),
    issueIds: [2, 3],
    instructions: 'Lorem ipsum dolor sit amet'
  },
};
