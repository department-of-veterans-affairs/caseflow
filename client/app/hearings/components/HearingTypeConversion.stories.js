import React from 'react';

import { HearingTypeConversion } from './HearingTypeConversion';
import { legacyAppealForTravelBoard } from '../../../test/data/appeals';
import { queueWrapper as Wrapper } from '../../../test/data/stores/queueStore';

export default {
  title: 'Hearings/Components/HearingTypeConversion',
  component: HearingTypeConversion,
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 760,
    },
  }
};

const Template = (args) => {
  const { storeArgs, componentArgs } = args;

  return (
    <Wrapper {...storeArgs}>
      <HearingTypeConversion
        {...componentArgs}
      />
    </Wrapper>
  );
};

export const ToVirtual = Template.bind({});
ToVirtual.args = {
  componentArgs: {
    appeal: legacyAppealForTravelBoard,
    type: 'Virtual'
  }
};
