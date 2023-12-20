import React from 'react';

import { IssueRemandReasonsForm } from './IssueRemandReasonsForm';

/* eslint-disable react/prop-types */

const issue = {
  id: 1,
  benefit_type: 'education',
  description: 'Lorem ipsum and whatnot',
  diagnostic_code: '503',
  disposition: 'remanded',
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
    issueTotal: 2,
  },
  argTypes: {
    onChange: { action: 'onChange' },
  },
};

const Template = (args) => <IssueRemandReasonsForm {...args} />;

export const AMA = Template.bind({});
AMA.args = { isLegacyAppeal: false };

export const Legacy = Template.bind({});
Legacy.args = { isLegacyAppeal: true };

export const DefaultValues = Template.bind({});
DefaultValues.args = {
  isLegacyAppeal: false,
  values: [
    { code: 'incorrect_notice_sent', checked: true, post_aoj: false },
    { code: 'medical_opinions', checked: true, post_aoj: true },
  ]
};
