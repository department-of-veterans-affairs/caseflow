import React, { useState } from 'react';

import BenefitType from './BenefitType';

export default {
  title: 'Intake/Components/BenefitTypes',
  parameters: {
    controls: {
      expanded: true
    }
  }
};

const defaultProps = {
  register: () => null,
  formName: 'higherLevelReview',
  userCanSelectVha: false,
  featureToggles: { vhaClaimReviewEstablishment: true }
};

const Template = (args) => {
  const [value, setValue] = useState('');

  return <BenefitType
    {...args}
    onChange={(newVal) => setValue(newVal)}
    value={value}
  />;
};

export const HigherLevelReviewAsVhaStaff = Template.bind({});
HigherLevelReviewAsVhaStaff.args = {
  ...defaultProps,
  userCanSelectVha: true
};

HigherLevelReviewAsVhaStaff.parameters = {
  docs: {
    storyDescription: 'On an HLR form, a VHA staff member will be able to select the VHA benefit type.'
  }
};

export const HigherLevelReviewAsNonVhaStaff = Template.bind({});
HigherLevelReviewAsNonVhaStaff.args = defaultProps;

HigherLevelReviewAsNonVhaStaff.parameters = {
  docs: {
    storyDescription:
      'On an HLR form, a non-VHA staff member will not be able to select the VHA benefit type.' +
        ' A tooltip appears if the option is hovered over'
  }
};

export const SupplementalClaimAsVhaStaff = Template.bind({});
SupplementalClaimAsVhaStaff.args = {
  ...defaultProps,
  formName: 'supplementalClaim',
  userCanSelectVha: true
};

SupplementalClaimAsVhaStaff.parameters = {
  docs: {
    storyDescription: 'On a SC form, a VHA staff member will be able to select the VHA benefit type.'
  }
};

export const SupplementalClaimAsNonVhaStaff = Template.bind({});
SupplementalClaimAsNonVhaStaff.args = {
  ...defaultProps,
  formName: 'supplementalClaim'
};

SupplementalClaimAsNonVhaStaff.parameters = {
  docs: {
    storyDescription:
      'On a SC form, a non-VHA staff member will not be able to select the VHA benefit type.' +
        ' A tooltip appears if the option is hovered over'
  }
};
