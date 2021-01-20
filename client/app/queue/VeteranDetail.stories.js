import React from 'react';

import { UnconnectedVeteranDetail as VeteranDetail } from './VeteranDetail';

import { amaAppeal, veteranInfo } from '../../test/data/appeals';

export default {
  title: 'Queue/VeteranDetail',
  component: VeteranDetail,
  parameters: { controls: { expanded: true } },
  args: {
    appealId: amaAppeal.externalId,
    error: false,
    loading: false,
    stateOnly: false,
    veteranInfo
  },
  argTypes: {
    getAppealValue: { action: 'getAppealValue' },
    appealId: { type: 'string' },
    error: { type: 'boolean' },
    loading: { type: 'boolean' },
    stateOnly: { type: 'boolean' },
    veteranInfo: { type: 'object' }
  },
};

const Template = (args) => <VeteranDetail {...args} />;

export const Default = Template.bind({});

export const StateOnly = Template.bind({});
StateOnly.args = { stateOnly: true };

export const Loading = Template.bind({});
Loading.args = { loading: true, veteranInfo: null };

export const Error = Template.bind({});
Error.args = { error: true, veteranInfo: null };
