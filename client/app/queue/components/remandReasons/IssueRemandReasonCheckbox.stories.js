import React from 'react';

import { IssueRemandReasonCheckbox } from './IssueRemandReasonCheckbox';

/* eslint-disable react/prop-types */

const option = { id: 'lorem', label: 'Lorem Ipsum' };

export default {
  title: 'Queue/Components/Remand Reasons/IssueRemandReasonCheckbox',
  component: IssueRemandReasonCheckbox,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    option,
  },
  argTypes: {
    onChange: { action: 'onChange' },
  },
};

const Template = (args) => <IssueRemandReasonCheckbox {...args} />;

export const AMA = Template.bind({});
AMA.args = { isLegacyAppeal: false };

export const Legacy = Template.bind({});
Legacy.args = { isLegacyAppeal: true };

export const DefaultValue = Template.bind({});
DefaultValue.args = {
  isLegacyAppeal: false,
  value: { code: option.id, post_aoj: true },
};
