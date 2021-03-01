import React from 'react';

import DocketSwitchAlertBanner from './DocketSwitchAlertBanner';

const fullGrantDocketSwitch = {
  disposition: 'granted',
  docket_type: 'direct_review',
  new_docket_stream_id: '2',
  old_docket_stream_id: '1'
};

const appeal = {
  externalId: '1',
  docketSwitch: fullGrantDocketSwitch
};

// const partialGrantDocketSwitch = {
// 	disposition: 'partially_granted',
// 	docket_type: 'evidence_submission'
// }

// const appeal2 = {
//   externalId: '2',
//   issues: [
//     { id: 3, program: 'compensation', description: 'issue description 3' },
//     { id: 4, program: 'compensation', description: 'issue description 4' },
//   ],
//   veteranFullName: 'John Doe',
//   veteranFileNumber: '123456789',
//   veteranInfo: {
//     veteran: {
//       full_name: 'John Doe',
//     },
//   },
// };

export default {
  title: 'Queue/Docket Switch/DocketSwitchAlertBanner',
  component: DocketSwitchAlertBanner,
  parameters: {},
  args: {
  	appeal: appeal
  }
};

const Template = (args) => (
  <DocketSwitchAlertBanner {...args} />
);

export const Basic = Template.bind({});
// FullGrant.args = {
//   appeal: appeal
// };

// export const PartialGrantNewDocket = Template.bind({});
// PartialGrantNewDocket.args = {
//   appeal: appeal
// };

// export const PartialGrantOldDocket = Template.bind({});
// PartialGrantOldDocket.args = {
//   appeal: appeal
// };
