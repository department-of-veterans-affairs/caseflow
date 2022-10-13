import React from 'react';
import { useArgs } from '@storybook/client-api';

import { SelectClaimant } from './SelectClaimant';

const relationships = [
  { value: '123456', displayText: 'Bob Vance, Spouse' },
  { value: '654321', displayText: 'Cathy Smith, Child' },
  { value: '789123', displayText: 'Tom Brady, Child' },
];

const defaultArgs = {
  appellantName: 'Jane Doe',
  formType: 'appeal',
  isVeteranDeceased: false,
  veteranIsNotClaimant: true,
  enableAddClaimant: true,
  relationships,
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
  const [updateArgs] = useArgs();
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

export const HLRWithVBMSBenTypes = Template.bind({});
HLRWithVBMSBenTypes.args = {
  appellantName: 'Jane Doe',
  formType: 'higher_level_review',
  isVeteranDeceased: false,
  veteranIsNotClaimant: true,
  enableAddClaimant: true,
  relationships,
  benefitType: 'pension',
};

export const HLRWithNonVBMSBenTypes = Template.bind({});
HLRWithNonVBMSBenTypes.args = {
  appellantName: 'Jane Doe',
  formType: 'higher_level_review',
  isVeteranDeceased: false,
  veteranIsNotClaimant: true,
  enableAddClaimant: true,
  relationships,
  benefitType: 'education',
};

export const SCWithVBMSBenTypes = Template.bind({});
SCWithVBMSBenTypes.args = {
  appellantName: 'Jane Doe',
  formType: 'higher_level_review',
  isVeteranDeceased: false,
  veteranIsNotClaimant: true,
  enableAddClaimant: true,
  relationships,
  benefitType: 'pension',
};

export const SCWithNonVBMSBenTypes = Template.bind({});
SCWithNonVBMSBenTypes.args = {
  appellantName: 'Jane Doe',
  formType: 'higher_level_review',
  isVeteranDeceased: false,
  veteranIsNotClaimant: true,
  enableAddClaimant: true,
  relationships,
  benefitType: 'education',
};
