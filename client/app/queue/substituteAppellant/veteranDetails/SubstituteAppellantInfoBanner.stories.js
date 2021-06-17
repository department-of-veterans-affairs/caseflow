import React from 'react';
import { MemoryRouter } from 'react-router';

import SubstituteAppellantInfoBanner from './SubstituteAppellantInfoBanner';

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

const appeal = {
  externalId: '1',
  docketSwitch: fullGrantDocketSwitch
};

export default {
  title: 'Queue/Substitute Appellant/SubstituteAppellantInfoBanner',
  component: SubstituteAppellantInfoBanner,
  parameters: {},
  decorators: [RouterDecorator]
};

const Template = (args) => (
  <SubstituteAppellantInfoBanner {...args} />
);

export const Default = Template.bind({});
Default.args = {
  appeal
};
