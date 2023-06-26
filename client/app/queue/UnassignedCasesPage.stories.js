import React from 'react';
import UnassignedCasesPage from './UnassignedCasesPage';
import queueReducer, { initialState } from './reducers';
import ReduxBase from 'app/components/ReduxBase';
import { initialState as uiState } from 'app/queue/uiReducer/uiReducer';
import ApiUtil from '../../app/util/ApiUtil';
import { queueConfigData } from '../../test/data/camoQueueConfigData';
import { appealsData } from '../../test/data/camoAmaAppealsData';
import { amaTasksData } from '../../test/data/camoAmaTasksData';

// Define a custom stub function to replace the Api post method
// eslint-disable-next-line no-unused-vars
const stubGet = (url, options) => {
  return new Promise((resolve) => {
    const userData = {
      body: {
        user: {
          id: 7,
          cssId: 'CAMOUSER',
          fullName: 'Camo User',
          displayName: 'Camo User',
        }
      }
    };

    resolve({ body: { data: {}, document_count: 0, user: userData } });
  });
};

// Assign the stub function to ApiUtil get
ApiUtil.get = stubGet;

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
  const state = {};
  const { args } = options;

  state.queue = initialState;
  state.ui = uiState;

  state.queue.amaTasks = amaTasksData;
  state.queue.queueConfig = queueConfigData;
  state.queue.appeals = appealsData;

  state.ui.userCssId = 'TESTUSER';

  state.ui.activeOrganization = {
    id: 39,
    name: 'VHA CAMO',
    isVso: false,
    userCanBulkAssign: true
  };

  state.queue.vhaProgramOffices = vhaProgramOffices;

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
