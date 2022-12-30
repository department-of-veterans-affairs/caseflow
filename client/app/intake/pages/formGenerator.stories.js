import React, { useMemo } from 'react';
import { MemoryRouter } from 'react-router';
import { appealFormHeader, reviewAppealSchema } from './appeal/review';
import {
  higherLevelReviewFormHeader,
  reviewHigherLevelReviewSameOffice,
  reviewHigherLevelReviewFiledByVaGov,
  reviewHigherLevelReviewSchema,
} from './higherLevelReview/review';
import { rampElectionFormHeader, reviewRampElectionSchema } from './rampElection/review';
import { rampRefilingHeader, reviewRampRefilingSchema } from './rampRefiling/review';
import { reviewSupplementalClaimSchema, supplementalClaimHeader } from './supplementalClaim/review';
import { snakeCase } from 'lodash';

import FormGenerator from './formGenerator';

import ReduxBase from 'app/components/ReduxBase';
import { reducer, generateInitialState } from 'app/intake';
import { PAGE_PATHS } from '../constants';

const relationships = [
  { value: '123456', displayText: 'John Doe, Spouse' },
  { value: '654321', displayText: 'Jen Doe, Child' },
];

// Also taken from review.jsx
const generateHigherLevelReviewSchema = (featureToggles) => {
  const formFieldFeatureToggles = {
    filedByVaGovHlr: reviewHigherLevelReviewFiledByVaGov,
    updatedIntakeForms: reviewHigherLevelReviewSameOffice
  };

  return Object.keys(formFieldFeatureToggles).reduce((schema, toggle) => {
    if ((featureToggles[toggle] && toggle !== 'updatedIntakeForms') ||
      (!featureToggles[toggle] && toggle === 'updatedIntakeForms')) {
      return schema.concat(formFieldFeatureToggles[toggle]);
    }

    return schema;
  }, reviewHigherLevelReviewSchema);
};

// Taken from review.jsx
const headerMappings = {
  appeal: appealFormHeader,
  higher_level_review: higherLevelReviewFormHeader,
  supplemental_claim: supplementalClaimHeader,
  ramp_election: rampElectionFormHeader,
  ramp_refiling: rampRefilingHeader
};

// Also taken from review.jsx
const schemaMappings = (featureToggles) => ({
  appeal: reviewAppealSchema,
  higher_level_review: generateHigherLevelReviewSchema(featureToggles),
  supplemental_claim: reviewSupplementalClaimSchema,
  ramp_election: reviewRampElectionSchema,
  ramp_refiling: reviewRampRefilingSchema
});

const defaultArgs = {
  formName: 'appeal',
  formHeader: appealFormHeader,
  schema: reviewAppealSchema,
  featureToggles: {
    correctClaimReviews: false,
    covidTimelinessExemption: true,
    eduPreDocketAppeals: true,
    filedByVaGovHlr: true,
    updatedAppealForm: true,
    updatedIntakeForms: true,
    useAmaActivationDate: true,
    vhaClaimReviewEstablishment: true,
  },
};

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={[PAGE_PATHS.REVIEW]}>
    <Story />
  </MemoryRouter>
);

const FullReduxDecorator = (Story, options) => {
  const state = generateInitialState();
  const { args } = options;

  state.intake.formType = 'appeal';
  if (args.formName) {
    state.intake.formType = snakeCase(args.formName);
  }

  // Set up all state variables ahead of time so swapping formName doesn't cause issues
  state.appeal.isStarted = 'STARTED';
  state.appeal.relationships = relationships;
  state.higherLevelReview.isStarted = 'STARTED';
  state.higherLevelReview.relationships = relationships;
  state.supplementalClaim.isStarted = 'STARTED';
  state.supplementalClaim.relationships = relationships;
  state.rampRefiling.isStarted = 'STARTED';
  state.rampRefiling.relationships = relationships;
  state.rampElection.isStarted = 'STARTED';
  state.rampElection.relationships = relationships;

  if (args.featureToggles.vhaClaimReviewEstablishment) {
    state.featureToggles.vhaClaimReviewEstablishment = args.featureToggles.vhaClaimReviewEstablishment;
  }

  if (args.userIsVhaEmployee) {
    state.userInformation.userIsVhaEmployee = args.userIsVhaEmployee;
  }

  return <ReduxBase reducer={reducer} initialState={state}>
    <Story />
  </ReduxBase>;
};

export default {
  title: 'Intake/Review/Form Generator',
  component: FormGenerator,
  decorators: [],
  parameters: {},
  args: defaultArgs,
  argTypes: {
    formName: {
      options: ['appeal', 'higherLevelReview', 'supplementalClaim', 'rampRefiling', 'rampElection'],
      control: { type: 'select' },
      table: {
        // disable: true
      }
    },
    userIsVhaEmployee: {
      control: { type: 'boolean' }
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

const Template = (args) => {
  useMemo(() => {
    if (args.formName) {
      const formKey = snakeCase(args.formName);

      args.formHeader = headerMappings[formKey];
      args.schema = schemaMappings(args.featureToggles)[formKey];
    }
  }, [args.formName]);

  return <FormGenerator {...args} />;
};

export const AllIntakes = Template.bind({});
// AllIntakes.args = defaultArgs;
AllIntakes.decorators = [FullReduxDecorator, RouterDecorator];
