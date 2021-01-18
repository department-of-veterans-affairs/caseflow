import React from 'react';

import { queueWrapper as Wrapper } from '../../test/data/stores/queueStore';
import { amaAppeal } from '../../test/data/appeals';

import AddCavcRemandView from './AddCavcRemandView';

export default {
  title: 'Queue/AddCavcRemandView',
  component: AddCavcRemandView,
  parameters: { controls: { expanded: true } },
  args: {
    cavcRemandFeature: true,
    mdrFeature: true,
    reversalFeature: false,
    dismissalFeature: false,
  },
  argTypes: {
    cavcRemandFeature: { control: { type: 'boolean' } },
    mdrFeature: { control: { type: 'boolean' } },
    reversalFeature: { control: { type: 'boolean' } },
    dismissalFeature: { control: { type: 'boolean' } },
  }
};

const appealId = amaAppeal.externalId;

const Template = ({ cavcRemandFeature, mdrFeature, reversalFeature, dismissalFeature, ...componentArgs }) => {
  const storeArgs = {
    ui: {
      featureToggles: {
        cavc_remand: cavcRemandFeature,
        mdr_cavc_remand: mdrFeature,
        reversal_cavc_remand: reversalFeature,
        dismissal_cavc_remand: dismissalFeature
      }
    }
  };

  return <Wrapper {...storeArgs}>
    <AddCavcRemandView appealId={appealId} {...componentArgs} />
  </Wrapper>;
};

export const Default = Template.bind({});
