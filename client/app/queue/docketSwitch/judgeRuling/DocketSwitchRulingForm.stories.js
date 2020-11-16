import React from 'react';

import { DocketSwitchRulingForm } from './DocketSwitchRulingForm';

const clerkOfTheBoardAttorneys = [
  { value: 1, label: 'COB Attorney 1' },
  { value: 2, label: 'COB Attorney 2' },
];

const instructions = ["**Summary:** Summary\n\n**Is this a timely request:** Yes\n\n**Recommendation:** Grant all issues\n\n**Draft letter:** http://www.va.gov"];

export default {
  title: 'Queue/Docket Switch/DocketSwitchRulingForm',
  component: DocketSwitchRulingForm,
  decorators: [],
  parameters: {},
  args: {
    appellantName: 'Jane Doe',
    clerkOfTheBoardAttorneys,
    instructions,
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <DocketSwitchRulingForm {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'Used by a judge to make a ruling on a Docket Switch.',
  },
};

export const DefaultAttorney = Template.bind({});
DefaultAttorney.args = {
  defaultAttorneyId: 2
};
