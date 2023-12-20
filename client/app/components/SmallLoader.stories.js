import React from 'react';
import SmallLoader from './SmallLoader';

import { LOGO_COLORS } from '../constants/AppConstants';

export const Template = (args) => (
  <SmallLoader {...args} />
);

export const Loader = Template.bind({});
Loader.args = {message: "Loading...", spinnerColor: LOGO_COLORS.READER.ACCENT };
