import React from 'react';
import { useArgs } from '@storybook/client-api';

import { SelectClaimant } from './SelectClaimant';

const relationships = [
  { value: '123456', displayText: 'John Doe, Spouse' },
  { value: '654321', displayText: 'Jen Doe, Child' },
];

const featureToggles = {
  attorneyFees: false,
  nonVeteranClaimants: false,
};
const defaultArgs = {
  appellantName: 'Jane Doe',
  formType: 'appeal',
  isVeteranDeceased: false,
  veteranIsNotClaimant: true,
  enableAddClaimant: true,
  relationships,
  featureToggles,
};

export default {
  title: 'Intake/Review/SelectClaimant',
  component: SelectClaimant,
  decorators: [],
  parameters: {},
  args: defaultArgs,
  argTypes: {
    veteranIsNotClaimant: { control: 'boolean' },
  },
};

const Template = (args) => {
  const [_args, updateArgs] = useArgs();
  const handleSetClaimant = ({ claimant, claimantType }) =>
    updateArgs({ claimant, claimantType });

  const setVeteranIsNotClaimant = (veteranIsNotClaimant) =>
    updateArgs({ veteranIsNotClaimant });

  return (
    <SelectClaimant
      {...args}
      setClaimant={handleSetClaimant}
      setVeteranIsNotClaimant={setVeteranIsNotClaimant}
    />
  );
};

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'Used during intake process to select a claimant with some sort of relationship to the veteran',
  },
};

export const WithAttorneyFees = Template.bind({});
WithAttorneyFees.args = {
  ...defaultArgs,
  featureToggles: {
    attorneyFees: true,
  },
};

export const WithNonVeteranClaimants = Template.bind({});
WithNonVeteranClaimants.args = {
  ...defaultArgs,
  featureToggles: {
    nonVeteranClaimants: true,
  },
};
