import React from 'react';
import { useArgs } from '@storybook/client-api';

import { SelectClaimant } from './SelectClaimant';

const relationships = [
  { value: '123456', displayText: 'John Doe, Spouse' },
  { value: '654321', displayText: 'Jen Doe, Child' },
];

const featureToggles = {
  attorneyFees: true,
  establishFiduciaryEps: true,
  nonVeteranClaimants: true,
};

export default {
  title: 'Intake/Review/SelectClaimant',
  component: SelectClaimant,
  decorators: [],
  parameters: {},
  args: {
    appellantName: 'Jane Doe',
    benefitType: 'appeal',
    isVeteranDeceased: false,
    veteranIsNotClaimant: true,
    relationships,
    featureToggles,
  },
  argTypes: {
    veteranIsNotClaimant: { control: 'boolean' },
  },
};

const Template = (args) => {
  const [_args, updateArgs] = useArgs();
  const handleSetClaimant = ({ claimant, claimantType }) =>
    updateArgs({ claimant, claimantType });

  return <SelectClaimant {...args} setClaimant={handleSetClaimant} />;
};

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'Used during intake process to select a claimant with some sort of relationship to the veteran',
  },
};
