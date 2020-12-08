import React from 'react';

import { UnconnectedVeteranState as VeteranState } from './VeteranDetail';

import { veteranInfo } from '../../test/data/appeals';

export default {
  title: 'Queue/VeteranState',
  component: VeteranState,
  parameters: { controls: { expanded: true } },
};

const Template = (args) => <VeteranState {...args} />;

export const Default = Template.bind({});
Default.args = { veteranInfo };

export const Loading = Template.bind({});
Loading.args = { loading: true, veteranInfo: null };

export const Error = Template.bind({});
Error.args = { error: true, veteranInfo: null };
