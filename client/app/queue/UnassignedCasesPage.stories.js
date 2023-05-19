import React from 'react';
import UnassignedCasesPage from './UnassignedCasesPage';
import queueReducer, { initialState } from './reducers';
import ReduxBase from 'app/components/ReduxBase';
import { initialState as uiState } from 'app/queue/uiReducer/uiReducer';

const vhaProgramOffices = {
  data: [
    {
      id: '41',
      type: 'organization',
      attributes: {
        id: 41,
        name: 'Community Care - Payment Operations Management'
      }
    },
    {
      id: '42',
      type: 'organization',
      attributes: {
        id: 42,
        name: 'Community Care - Veteran and Family Members Program'
      }
    },
    {
      id: '43',
      type: 'organization',
      attributes: {
        id: 43,
        name: 'Member Services - Health Eligibility Center'
      }
    },
    {
      id: '44',
      type: 'organization',
      attributes: {
        id: 44,
        name: 'Member Services - Beneficiary Travel'
      }
    },
    {
      id: '45',
      type: 'organization',
      attributes: {
        id: 45,
        name: 'Prosthetics'
      }
    }
  ]
};

const ReduxDecorator = (Story, options) => {
  const state = initialState;
  const { args } = options;

  state.ui = uiState;

  state.ui.userCssId = 'TESTUSER';

  state.vhaProgramOffices = vhaProgramOffices;

  state.ui.userIsCamoEmployee = args.userIsCamoEmployee;

  return <ReduxBase reducer={queueReducer} initialState={state}>
    <Story />
  </ReduxBase>;
};

export default {
  title: 'Queue/Bulk Assign/Unassigned Cases Page',
  component: UnassignedCasesPage,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {},
  argTypes: {
    userIsCamoEmployee: {
      control: { type: 'boolean' }
    },
  },
};

const Template = (args) => {
  return <UnassignedCasesPage {...args} />;
};

export const Normal = Template.bind({});
