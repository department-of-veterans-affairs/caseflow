import React from 'react';
import { MemoryRouter } from 'react-router';
import { PAGE_PATHS } from '../constants';
import { sample1 } from '../../../test/app/intake/testData';
import ReduxBase from 'app/components/ReduxBase';
import { reducer, generateInitialState } from 'app/intake';

import AddIssuesModal from './AddIssuesModal';

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={[PAGE_PATHS.ADD_ISSUES]}>
    <Story />
  </MemoryRouter>
);

const ReduxDecorator = (Story) => (<ReduxBase reducer={reducer} initialState={generateInitialState()}>
  <Story />
</ReduxBase>
);

const defaultArgs = {
  intakeData: sample1.intakeData
};

export default {
  title: 'Intake/Add Issues/Add Issues Modal',
  component: AddIssuesModal,
  decorators: [ReduxDecorator, RouterDecorator],
  parameters: {},
  args: defaultArgs,
  argTypes: {
  },
};

const Template = (args) => (<AddIssuesModal {...args} />);

export const basic = Template.bind({});
