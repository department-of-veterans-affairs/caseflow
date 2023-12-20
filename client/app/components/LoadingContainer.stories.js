import React from 'react';
import LoadingContainer from './LoadingContainer';

import { LOGO_COLORS } from '../constants/AppConstants';

export const Template = (args) => (
  <LoadingContainer {...args}>
    <div className="cf-image-loader"></div>
    <p className="cf-txt-c"> Gathering information in VBMS now......</p>
  </LoadingContainer>
);

export const Loader = Template.bind({});
Loader.args = { color: LOGO_COLORS.CERTIFICATION.ACCENT };
