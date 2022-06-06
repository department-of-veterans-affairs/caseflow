import React from 'react';

import { HearingTypeConversion } from './HearingTypeConversion';
import { HearingTypeConversionProvider } from '../contexts/HearingTypeConversionContext';

const HearingTypeConversionContainer = ({ type, props }) => {
  return (
    <HearingTypeConversionProvider>
      <HearingTypeConversion type={type} props={props} />
    </HearingTypeConversionProvider>
  );
};

export default HearingTypeConversionContainer;
