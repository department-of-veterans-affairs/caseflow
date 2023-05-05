import React, { useMemo } from 'react';
import UnassignedCasesPage from './UnassignedCasesPage';
import queueReducer, { initialState } from './reducers';
import ReduxBase from 'app/components/ReduxBase';
import { initialState as uiState } from 'app/queue/uiReducer/uiReducer';
import { amaTasksSplit } from '../../test/data/tasks';
import { target } from 'glamor';
import { camoTasks } from '../../test/data/camoTasks';

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

const FullReduxDecorator = (Story, options) => {
  const state = initialState;
  const { args } = options;

  state.ui = uiState;

  state.ui.userCssId = 'TYLERNAVTEST';

  state.ui.userInfo = {
    id: 3943,
    cssId: 'TYLERNAVTEST',
    fullName: 'Tyler Broyles',
    displayName: 'TYLERNAVTEST (VACO)'
  };

  state.vhaProgramOffices = vhaProgramOffices;

  state.amaTasks = camoTasks;

  // state.tasks = amaTasksSplit;

  console.log('initial state is:');

  // state.ui = {};

  // state.intake.formType = 'appeal';
  // if (args.formName) {
  //   state.intake.formType = snakeCase(args.formName);
  // }

  // Set up all state variables ahead of time so swapping formName doesn't cause issues
  // state.appeal.isStarted = 'STARTED';
  // state.appeal.relationships = relationships;
  // state.higherLevelReview.isStarted = 'STARTED';
  // state.higherLevelReview.relationships = relationships;
  // state.supplementalClaim.isStarted = 'STARTED';
  // state.supplementalClaim.relationships = relationships;
  // state.rampRefiling.isStarted = 'STARTED';
  // state.rampRefiling.relationships = relationships;
  // state.rampElection.isStarted = 'STARTED';
  // state.rampElection.relationships = relationships;

  // if (args.featureToggles.vhaClaimReviewEstablishment) {
  //   state.featureToggles.vhaClaimReviewEstablishment = args.featureToggles.vhaClaimReviewEstablishment;
  // }

  // if (args.userIsCamoEmployee) {
  //   console.log(state);
  //   console.log(args.userIsCamoEmployee);
  //   // state.userInformation.userIsVhaEmployee = args.userIsVhaEmployee;
  //   state.ui.userIsCamoEmployee = args.userIsCamoEmployee;
  //   // state.userIsCamoEmployee = args.userIsCamoEmployee;
  // }

  // if (args.userIsCamoEmployee) {
  //   state.amaTasks = camoTasks;
  // } else {
  //   state.amaTasks = [];
  // }

  state.ui.userIsCamoEmployee = args.userIsCamoEmployee;

  console.log(state);

  return <ReduxBase reducer={queueReducer} initialState={state}>
    <Story />
  </ReduxBase>;
};

export default {
  title: 'Queue/Bulk Assign/Unassigned Cases Page',
  component: UnassignedCasesPage,
  decorators: [FullReduxDecorator],
  parameters: {},
  // args: defaultArgs,
  // args: { tasks: Object.values(camoTasks).map((value) => (value)) },
  args: { tasks: [1, 2, 3] },
  argTypes: {
    userIsCamoEmployee: {
      control: { type: 'boolean' }
    },
  },
};

const Template = (args) => {
  // useMemo(() => {
  //   if (args.formName) {
  //     const formKey = snakeCase(args.formName);

  //     args.formHeader = headerMappings[formKey];
  //     args.schema = schemaMappings(args.featureToggles)[formKey];
  //   }
  // }, [args.formName]);

  return <UnassignedCasesPage {...args} />;
};

export const Normal = Template.bind({});
// AllIntakes.args = defaultArgs;
// AllIntakes.decorators = [FullReduxDecorator, RouterDecorator];
