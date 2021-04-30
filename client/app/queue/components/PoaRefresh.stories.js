import React from 'react';

import { queueWrapper as Wrapper } from '../../../test/data/stores/queueStore';
import { amaAppeal } from '../../../test/data/appeals';

import { PoaRefresh } from './PoaRefresh';

export default {
  title: 'Queue/PoaRefresh',
  component: PoaRefresh,
  parameters: { controls: { expanded: true } },
  args: {
    poaSyncDateFeature: true,
    powerOfAttorney: { poa_last_synced_at: '04/08/2021' }
  },
  argTypes: {
    poaSyncDateFeature: { control: { type: 'boolean' } },
    powerOfAttorney: { control: { type: 'string' } }
  }
};

const appealId = amaAppeal.externalId;

const Template = ({ poaSyncDateFeature, ...componentArgs }) => {
  const storeArgs = {
    ui: {
      featureToggles: {
        poa_sync_date: poaSyncDateFeature
      }
    }
  };

  return <Wrapper {...storeArgs}>
    <PoaRefresh appealId={appealId} {...componentArgs} />
  </Wrapper>;
};


export const Default = Template.bind({});
