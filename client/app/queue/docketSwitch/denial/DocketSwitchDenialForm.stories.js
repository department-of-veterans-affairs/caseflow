import React from 'react';

import { DocketSwitchDenialForm } from './DocketSwitchDenialForm';

const instructions = ['**Summary:** Summary\n\n**Is this a timely request:** Yes\n\n**Recommendation:** Grant all issues\n\n**Draft letter:** http://www.va.gov'];

export default {
  title: 'Queue/Docket Switch/DocketSwitchDenialForm',
  component: DocketSwitchDenialForm,
  decorators: [],
  parameters: {},
  args: {
    appellantName: 'Jane Doe',
    instructions,
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <DocketSwitchDenialForm {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'Used by attorney in Clerk of the Board office to complete a denial of a docket switch request',
  },
};

