import React from 'react';

import VeteranDetail from './VeteranDetail';

import { amaAppeal, veteranInfo } from '../../test/data/appeals';
import { queueWrapper as Wrapper } from '../../test/data/stores/queueStore';

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

const Template = ({ error, loading, veteranInfo, ...args }) => {
  const storeArgs = {
    queue: {
      appealDetails: {
        [amaAppeal.externalId]: {
          ...amaAppeal,
          veteranInfo
        }
      },
      loadingAppealDetail: {
        [amaAppeal.externalId]: {
          loading,
          error
        }
      }
    }
  };

  return (
    <Wrapper {...storeArgs}>
      <VeteranDetail {...args} />
    </Wrapper>
  );
};

export const Default = Template.bind({});

export const StateOnly = Template.bind({});
StateOnly.args = { stateOnly: true };

export const Loading = Template.bind({});
Loading.args = { loading: true, veteranInfo: null };

export const Error = Template.bind({});
Error.args = { error: true, veteranInfo: null };
