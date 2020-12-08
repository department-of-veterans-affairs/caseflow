import React from 'react';

import { UnconnectedVeteranDetail as VeteranDetail } from './VeteranDetail';

import { veteranInfo } from '../../test/data/appeals';

export default {
  title: 'Queue/VeteranDetail',
  component: VeteranDetail,
  parameters: { controls: { expanded: true } },
};

const Template = (args) => <VeteranDetail {...args} />;

export const Default = Template.bind({});
Default.args = { veteranInfo };

export const Loading = Template.bind({});
Loading.args = { loading: true, veteranInfo: null };

export const Error = Template.bind({});
Error.args = { error: true, veteranInfo: null };
