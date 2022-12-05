import React from 'react';
import { useArgs } from '@storybook/client-api';

import { SelectClaimant } from './SelectClaimant';

const relationships = [
  { value: '123456', displayText: 'Bob Vance, Spouse' },
  { value: '654321', displayText: 'Cathy Smith, Child' },
  { value: '789123', displayText: 'Tom Brady, Child' },
];

const defaultArgs = {
  formType: 'appeal',
  isVeteranDeceased: false,
  veteranIsNotClaimant: true,
  enableAddClaimant: true,
  featureToggles: { hlrScUnrecognizedClaimants: true },
  benefitType: 'education',
  relationships,
};

export default {
  title: 'Intake/Review/Select Claimant',
  component: SelectClaimant,
  decorators: [],
  parameters: {},
  args: defaultArgs,
  argTypes: {
    veteranIsNotClaimant: { control: 'boolean' },
    featureToggles: { control: 'object' },
    benefitType: { control: { type: 'select', options: ['pension', 'education'] } },
    formType: {
      control: {
        type: 'select',
        options: [
          'appeal', 'higher_level_review', 'supplemental_claim', 'ramp_refilling', 'ramp_election'
        ]
      }
    },
  },
};

const Template = (args) => {
  // eslint-disable-next-line no-unused-vars
  const [_, updateArgs] = useArgs();

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
Basic.args = {};
Basic.storyName = 'Default Select Claimant';
Basic.parameters = {
  docs: {
    storyDescription:
      'Used during intake process to select a claimant with some sort of relationship to the veteran',
  },
};
