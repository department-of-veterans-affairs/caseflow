import React from 'react';

import { HearingTypeConversionModal } from './HearingTypeConversionModal';
import { appealData } from '../../../test/data/appeals';
import { queueWrapper as Wrapper } from '../../../test/data/stores/queueStore';

export default {
  title: 'Hearings/Components/HearingTypeConversionModal',
  component: HearingTypeConversionModal,
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
      <HearingTypeConversionModal
        {...componentArgs}
      />
    </Wrapper>
  );
};

export const ToVideo = Template.bind({});
ToVideo.args = {
  componentArgs: {
    appeal: appealData,
    hearingType: 'Video'
  }
};

export const ToCentral = Template.bind({});
ToCentral.args = {
  componentArgs: {
    appeal: appealData,
    hearingType: 'Central'
  }
};
