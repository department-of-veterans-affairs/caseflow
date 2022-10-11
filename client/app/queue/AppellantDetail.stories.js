import React from 'react';

import { AppellantDetail } from './AppellantDetail';

import { appealData as appeal } from '../../test/data/appeals';
import { APPELLANT_TYPES } from './constants';

const selectAppellantDetails = ({ appellantFullName, appellantAddress, appellantRelationship, appellantType }) =>
  ({ appellantFullName, appellantAddress, appellantRelationship, appellantType });

export default {
  title: 'Queue/Case Details/AppellantDetail',
  component: AppellantDetail,
  parameters: { controls: { expanded: true } },
};

const Template = (args) => <AppellantDetail appeal={{ ...args }} />;

export const Default = Template.bind({});
Default.args = selectAppellantDetails(appeal);

export const WithHealthcareProviderClaimant = Template.bind({});
WithHealthcareProviderClaimant.args = selectAppellantDetails(
  {
    ...appeal,
    appellantRelationship: 'Healthcare Provider',
    appellantType: APPELLANT_TYPES.HEALTHCARE_PROVIDER_CLAIMANT
  }
);

export const WithOtherClaimant = Template.bind({});
WithOtherClaimant.args = selectAppellantDetails(
  {
    ...appeal,
    appellantRelationship: 'Other',
    appellantType: APPELLANT_TYPES.OTHER_CLAIMANT
  }
);

export const WithAttorneyClaimant = Template.bind({});
WithAttorneyClaimant.args = selectAppellantDetails(
  {
    ...appeal,
    appellantRelationship: 'Attorney',
    appellantType: APPELLANT_TYPES.ATTORNEY_CLAIMANT
  }
);
