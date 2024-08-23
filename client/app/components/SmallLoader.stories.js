import React from 'react';
import SmallLoader from './SmallLoader';

import { LOGO_COLORS } from '../constants/AppConstants';

export const Template = (args) => (
  <SmallLoader {...args} />
);

const Loader = Template.bind({});
export default {
  component: Loader,
};
Loader.args = {message: "Loading...", spinnerColor: LOGO_COLORS.READER.ACCENT };
