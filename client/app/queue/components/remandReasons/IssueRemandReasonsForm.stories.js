import React from 'react';

import { IssueRemandReasonsForm } from './IssueRemandReasonsForm';

/* eslint-disable react/prop-types */

const issue = {};

export default {
  title: 'Queue/Components/Remand Reasons/IssueRemandReasonsForm',
  component: IssueRemandReasonsForm,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    issue,
  },
  argTypes: {},
};

const Template = (args) => <IssueRemandReasonsForm {...args} />;

export const AMA = Template.bind({});
AMA.args = { isLegacyAppeal: false };

export const Legacy = Template.bind({});
Legacy.args = { isLegacyAppeal: true };
