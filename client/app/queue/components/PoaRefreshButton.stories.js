import React from 'react';

import { queueWrapper as Wrapper } from '../../../test/data/stores/queueStore';
import { amaAppeal } from '../../../test/data/appeals';

import { PoaRefreshButton } from './PoaRefreshButton';

export default {
  title: 'Queue/PoaRefreshButton',
  component: PoaRefreshButton,
  parameters: { controls: { expanded: true } },
  args: {
    PoaRefreshButtonFeature: true,
    appealId: amaAppeal.externalId
  },
  argTypes: {
    appealId: { control: { type: 'number' } }
  }
};


const Template = ({ PoaRefreshButtonFeature, ...componentArgs }) => {
  const storeArgs = {
    ui: {
      featureToggles: {
        poa_button_refresh: PoaRefreshButtonFeature
      }
    }
  };

  return <Wrapper {...storeArgs}>
    <PoaRefreshButton appealId={amaAppeal.externalId}  {...componentArgs} />
  </Wrapper>;
};

export const Default = Template.bind({});
