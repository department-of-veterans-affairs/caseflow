import React from 'react';

import { PoaRefresh } from './PoaRefresh';

const Template = (args) => (
  <PoaRefresh {...args} />
);

export const POASyncDate = Template.bind({});
POASyncDate.args = {
  powerOfAttorney: { poa_last_synced_at: '04/07/2021' },
};
