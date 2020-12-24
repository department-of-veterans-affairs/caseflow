import React from 'react';

import { AppellantDetail } from './AppellantDetail';

import { appealData as appeal } from '../../test/data/appeals';

const selectAppellantDetails = ({ appellantFullName, appellantAddress, appellantRelationship }) =>
  ({ appellantFullName, appellantAddress, appellantRelationship });

export default {
  title: 'Queue/AppellantDetail',
  component: AppellantDetail,
  parameters: { controls: { expanded: true } },
};

const Template = (args) => <AppellantDetail appeal={{ ...args }} />;

export const Default = Template.bind({});
Default.args = selectAppellantDetails(appeal);
