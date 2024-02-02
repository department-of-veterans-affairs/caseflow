import React from 'react';
import UnassignedCasesPage from './UnassignedCasesPage';
import queueReducer, { initialState } from './reducers';
import ReduxBase from 'app/components/ReduxBase';
import { initialState as uiState } from 'app/queue/uiReducer/uiReducer';
import ApiUtil from '../../app/util/ApiUtil';
import { queueConfigData } from '../../test/data/camoQueueConfigData';
import { appealsData } from '../../test/data/camoAmaAppealsData';
import { amaTasksData } from '../../test/data/camoAmaTasksData';
import { sctAmaTasksData } from '../../test/data/sctAmaTasksData';
import faker from 'faker';
import { sctQueueConfigData } from '../../test/data/sctQueueConfigData';
import { sctAmaAppealsData } from '../../test/data/sctAmaAppealsData';

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

const attorneyData = {
  data: Array.from({ length: 5 }, (_, i) => ({
    full_name: faker.name.findName(),
    id: i + 1,
    station_id: '101',
    css_id: `TESTING${i + 1}`
  }))
};

// This id has to match the id of the assigned to in your amaTasks test data
const testCamoOrg = {
  id: 39,
  name: 'VHA CAMO',
  isVso: false,
  userCanBulkAssign: true
};

// This id has to match the id of the assigned to in your amaTasks test data
const testSpecialtyCaseTeamOrg = {
  id: 67,
  name: 'Specialty Case Team',
  isVso: false,
  userCanBulkAssign: true
};

const ReduxDecorator = (Story, options) => {
  const state = {};
  const { args } = options;

  state.queue = initialState;
  state.ui = uiState;

  state.ui.userCssId = 'TESTUSER';

  // TODO: To make this work for sct I need new tasks data and new queue config data.
  // I also need to stub attorneys like vhaProgramOffices and set it in the redux store
  // I would need to switch on all of these things based on the args.userIsSCTEmployee and userIsCamoEmployee
  // Active org might need to be switched too not sure.

  if (args.userIsSCTCoordinator) {
    state.ui.userIsSCTCoordinator = args.userIsSCTCoordinator;
    state.ui.activeOrganization = testSpecialtyCaseTeamOrg;
    state.userIsCamoEmployee = false;
    state.queue.attorneys = attorneyData;
    state.queue.amaTasks = sctAmaTasksData;
    state.queue.queueConfig = sctQueueConfigData;
    state.queue.appeals = sctAmaAppealsData;
  } else if (args.userIsCamoEmployee) {
    state.ui.userIsCamoEmployee = args.userIsCamoEmployee;
    state.ui.activeOrganization = testCamoOrg;
    state.ui.userIsSCTCoordinator = false;
    state.queue.vhaProgramOffices = vhaProgramOffices;
    state.queue.amaTasks = amaTasksData;
    state.queue.queueConfig = queueConfigData;
    state.queue.appeals = appealsData;
  } else {
    state.ui.userIsSCTCoordinator = false;
    state.ui.userIsCamoEmployee = false;
    state.queue.attorneys = attorneyData;

  }

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
    userIsSCTCoordinator: {
      control: { type: 'boolean' }
    }
  },
};

const Template = (args) => {
  return <UnassignedCasesPage {...args} />;
};

export const Normal = Template.bind({});
