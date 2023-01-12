import React from 'react';
import CancelIntakeModal from './CancelIntakeModal';
import ReduxBase from 'app/components/ReduxBase';
import { reducer, generateInitialState } from 'app/intake';

const ReduxDecorator = (Story) => (
  <ReduxBase reducer={reducer} initialState={generateInitialState()}>
    <Story />
  </ReduxBase>
);

export default {
  title: 'Intake/Cancel Intake Modal',
  component: CancelIntakeModal,
  decorators: [ReduxDecorator],
  args: {
  },
  argTypes: {
  },
};

const Template = (args) => <CancelIntakeModal {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'This is modal used to cancel an intake',
  },
};
