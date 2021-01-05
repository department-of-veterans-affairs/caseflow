import React from 'react';

import { queueWrapper as Wrapper } from '../../test/data/stores/queueStore';
import { amaAppeal } from '../../test/data/appeals';

import AddCavcRemandView from './AddCavcRemandView';

export default {
  title: 'Queue/AddCavcRemandView',
  component: AddCavcRemandView,
  parameters: { controls: { expanded: true } },
  args: {
    cavcRemandToggled: true,
    mdrToggled: false,
    reversalToggled: false,
    dismissalToggled: false,
  },
  argTypes: {
    cavcRemandToggled: { control: { type: 'boolean' } },
    mdrToggled: { control: { type: 'boolean' } },
    reversalToggled: { control: { type: 'boolean' } },
    dismissalToggled: { control: { type: 'boolean' } },
  }
};

const appealId = amaAppeal.externalId;

const Template = ({ cavcRemandToggled, mdrToggled, reversalToggled, dismissalToggled, ...componentArgs }) => {
  const storeArgs = {
    ui: {
      featureToggles: {
        cavc_remand: cavcRemandToggled,
        mdr_cavc_remand: mdrToggled,
        reversal_cavc_remand: reversalToggled,
        dismissal_cavc_remand: dismissalToggled
      }
    }
  };

  return <Wrapper {...storeArgs}>
    <AddCavcRemandView appealId={appealId} {...componentArgs} />
  </Wrapper>;
};

export const Default = Template.bind({});
Default.args = { cavcRemandToggled: true };
