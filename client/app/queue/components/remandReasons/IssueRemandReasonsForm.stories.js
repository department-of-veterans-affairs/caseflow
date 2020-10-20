import React from 'react';

import { IssueRemandReasonsForm } from './IssueRemandReasonsForm';

/* eslint-disable react/prop-types */

const issue = {
  id: 1,
  benefit_type: 'education',
  description: 'Lorem ipsum and whatnot',
  diagnostic_code: '503',
  disposition: 'remanded'
};

export default {
  title: 'Queue/Components/Remand Reasons/IssueRemandReasonsForm',
  component: IssueRemandReasonsForm,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    issue,
    issueNumber: 1,
    issueTotal: 2
  },
  argTypes: {},
};

const Template = (args) => <IssueRemandReasonsForm {...args} />;

export const AMA = Template.bind({});
AMA.args = { isLegacyAppeal: false };

export const Legacy = Template.bind({});
Legacy.args = { isLegacyAppeal: true };
