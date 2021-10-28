import React from 'react';
import { LOGO_COLORS } from '../../app/constants/AppConstants';
import { LoadingSymbol } from '../../app/components/RenderFunctions';

export default {
  title: 'Commons/Components/Icons/LoadingSymbol',
  component: LoadingSymbol,
};

const Template = (args) => <LoadingSymbol {...args} />;

export const Default = Template.bind({});
Default.args = {
  text: '',
  size: '30px',
  color: LOGO_COLORS.DISPATCH.ACCENT
};

