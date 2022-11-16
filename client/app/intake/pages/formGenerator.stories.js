import React from 'react';
import { MemoryRouter } from 'react-router';
import { appealFormHeader, reviewAppealSchema } from './appeal/review';
import {
  higherLevelReviewFormHeader,
  reviewHigherLevelReviewSchema,
} from './higherLevelReview/review';
import { rampElectionFormHeader, reviewRampElectionSchema } from './rampElection/review';
import { rampRefilingHeader, reviewRampRefilingSchema } from './rampRefiling/review';
import { reviewSupplementalClaimSchema, supplementalClaimHeader } from './supplementalClaim/review';

import FormGenerator from './formGenerator';

import ReduxBase from 'app/components/ReduxBase';
import { reducer, generateInitialState } from 'app/intake';
import { PAGE_PATHS } from '../constants';

const relationships = [
  { value: '123456', displayText: 'John Doe, Spouse' },
  { value: '654321', displayText: 'Jen Doe, Child' },
];

const appealArgs = {
  formName: 'appeal',
  formHeader: appealFormHeader,
  schema: reviewAppealSchema,
  featureToggles: {},
};

const higherLevelReviewArgs = {
  formName: 'higherLevelReview',
  formHeader: higherLevelReviewFormHeader,
  schema: reviewHigherLevelReviewSchema,
  featureToggles: {}
};

const supplementalClaimArgs = {
  formName: 'supplementalClaim',
  formHeader: supplementalClaimHeader,
  schema: reviewSupplementalClaimSchema,
  featureToggles: {}
};

const rampRefilingArgs = {
  formName: 'rampRefiling',
  formHeader: rampRefilingHeader,
  schema: reviewRampRefilingSchema,
  featureToggles: {}
};

const rampElectionArgs = {
  formName: 'rampElection',
  formHeader: rampElectionFormHeader,
  schema: reviewRampElectionSchema,
  featureToggles: {}
};

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={[PAGE_PATHS.REVIEW]}>
    <Story />
  </MemoryRouter>
);

const ReduxDecoratorAppeal = (Story) => {
  const state = generateInitialState();

  // Setup initial state Values
  state.intake.formType = 'appeal';
  state.appeal.isStarted = 'STARTED';
  state.appeal.relationships = relationships;

  return <ReduxBase reducer={reducer} initialState={state}>
    <Story />
  </ReduxBase>;
};

const ReduxDecoratorHLR = (Story) => {
  const state = generateInitialState();

  // Setup initial state Values
  state.intake.formType = 'higher_level_review';
  state.higherLevelReview.isStarted = 'STARTED';
  state.higherLevelReview.relationships = relationships;

  return <ReduxBase reducer={reducer} initialState={state}>
    <Story />
  </ReduxBase>;
};

const ReduxDecoratorSC = (Story) => {
  const state = generateInitialState();

  // Setup initial state Values
  state.intake.formType = 'supplemental_claim';
  state.supplementalClaim.isStarted = 'STARTED';
  state.supplementalClaim.relationships = relationships;

  return <ReduxBase reducer={reducer} initialState={state}>
    <Story />
  </ReduxBase>;
};

const ReduxDecoratorRampRefiling = (Story) => {
  const state = generateInitialState();

  // Setup initial state Values
  state.intake.formType = 'ramp_refiling';
  state.rampRefiling.isStarted = 'STARTED';
  state.rampRefiling.relationships = relationships;

  return <ReduxBase reducer={reducer} initialState={state}>
    <Story />
  </ReduxBase>;
};

const ReduxDecoratorRampElection = (Story) => {
  const state = generateInitialState();

  // Setup initial state Values
  state.intake.formType = 'ramp_election';
  state.rampElection.isStarted = 'STARTED';
  state.rampElection.relationships = relationships;

  return <ReduxBase reducer={reducer} initialState={state}>
    <Story />
  </ReduxBase>;
};

export default {
  title: 'Intake/Review/Form Generator',
  component: FormGenerator,
  decorators: [],
  parameters: {},
  args: appealArgs,
  argTypes: {
    formName: {
      table: {
        disable: true
      }
    },
    formHeader: {
      table: {
        disable: true
      }
    },
    schema: {
      table: {
        disable: true
      }
    }
  },
};

const Template = (args) => (<FormGenerator {...args} />);

// Appeal Review
export const Appeal = Template.bind({});

Appeal.parameters = {
  docs: {
    storyDescription:
      'A FormGenerator for Appeals',
  },
};

Appeal.args = appealArgs;
Appeal.decorators = [ReduxDecoratorAppeal, RouterDecorator];

// Higher Level Review
export const HigherLevelReview = Template.bind({});

HigherLevelReview.parameters = {
  docs: {
    storyDescription:
      'A FormGenerator for Higher Level Reviews',
  },
};

HigherLevelReview.args = higherLevelReviewArgs;
HigherLevelReview.decorators = [ReduxDecoratorHLR, RouterDecorator];

// Supplemental Claim Review
export const SupplementalClaimReview = Template.bind({});

SupplementalClaimReview.parameters = {
  docs: {
    storyDescription:
      'A FormGenerator for Supplemental Claim Reviews',
  },
};

SupplementalClaimReview.args = supplementalClaimArgs;
SupplementalClaimReview.decorators = [ReduxDecoratorSC, RouterDecorator];

// Ramp Refiling Review
export const RampRefilingReview = Template.bind({});

RampRefilingReview.parameters = {
  docs: {
    storyDescription:
      'A FormGenerator for Ramp Refiling Reviews',
  },
};

RampRefilingReview.args = rampRefilingArgs;
RampRefilingReview.decorators = [ReduxDecoratorRampRefiling, RouterDecorator];

// Ramp Election Review
// Ramp Refiling Review
export const RampElectionReview = Template.bind({});

RampElectionReview.parameters = {
  docs: {
    storyDescription:
      'A FormGenerator for Ramp Refiling Reviews',
  },
};

RampElectionReview.args = rampElectionArgs;
RampElectionReview.decorators = [ReduxDecoratorRampElection, RouterDecorator];
