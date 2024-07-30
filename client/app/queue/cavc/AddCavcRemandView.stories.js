import React from 'react';

import { queueWrapper as Wrapper } from '../../../test/data/stores/queueStore';
import { amaAppeal } from '../../../test/data/appeals';

import AddCavcRemandView from './AddCavcRemandView';

export default {
  title: 'Queue/AddCavcRemandView',
  component: AddCavcRemandView,
  parameters: { controls: { expanded: true } },
  args: {
    mdrFeature: true,
    reversalFeature: false,
    dismissalFeature: false,
  },
  argTypes: {
    mdrFeature: { control: { type: 'boolean' } },
    reversalFeature: { control: { type: 'boolean' } },
    dismissalFeature: { control: { type: 'boolean' } },
  }
};

const appealId = amaAppeal.externalId;

const Template = ({ mdrFeature, reversalFeature, dismissalFeature, ...componentArgs }) => {
  const storeArgs = {
    ui: {
      featureToggles: {
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
