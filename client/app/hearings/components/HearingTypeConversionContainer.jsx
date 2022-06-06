import React from 'react';

import { HearingTypeConversion } from './HearingTypeConversion';
import { HearingTypeConversionProvider } from '../contexts/HearingTypeConversionContext';

const HearingTypeConversionContainer = (props) => {
  return (
    <HearingTypeConversionProvider>
      <HearingTypeConversion {...props} />
    </HearingTypeConversionProvider>
  );
};

export default HearingTypeConversionContainer;
