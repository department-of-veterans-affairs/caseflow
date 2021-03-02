import React from 'react';
import { MemoryRouter } from 'react-router';

import DocketSwitchAlertBanner from './DocketSwitchAlertBanner';

const RouterDecorator = (Story) => (
  <MemoryRouter>
	<Story />
  </MemoryRouter>
);

const fullGrantDocketSwitch = {
  disposition: 'granted',
  docket_type: 'direct_review',
  old_docket_stream_id: '1'
};

const partialGrantDocketSwitch = {
  disposition: 'partially_granted',
  docket_type: 'evidence_submission',
  new_docket_stream_id: '2',
  old_docket_stream_id: '3'
}

const appeal = {
  externalId: '1',
  docketSwitch: fullGrantDocketSwitch
};

const appeal2 = {
  externalId: '2',
  docketSwitch: partialGrantDocketSwitch
};

const appeal3 = {
  externalId: '3',
  docketSwitch: partialGrantDocketSwitch
};

export default {
  title: 'Queue/Docket Switch/DocketSwitchAlertBanner',
  component: DocketSwitchAlertBanner,
  parameters: {},
  decorators: [RouterDecorator]
};

const Template = (args) => (
  <DocketSwitchAlertBanner {...args} />
);

export const FullGrant = Template.bind({});
FullGrant.args = {
  appeal: appeal
};

export const PartialGrantNewDocket = Template.bind({});
PartialGrantNewDocket.args = {
  appeal: appeal2
};

export const PartialGrantOldDocket = Template.bind({});
PartialGrantOldDocket.args = {
  appeal: appeal3
};
