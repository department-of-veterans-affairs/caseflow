import React from 'react';

import AssignToView from './AssignToView';
import { queueWrapper as Wrapper } from '../../test/data/stores/queueStore';

export default {
  title: 'Queue/Components/Task Action Modals/AssignToView',
  component: AssignToView,
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
      <AssignToView
        {...componentArgs}
      />
    </Wrapper>
  );
};

export const BvaIntakeReturnsToVhaCamo = Template.bind({});

export const BvaIntakeReturnsToVhaCaregiverSupportProgram = Template.bind({});

export const BvaIntakeReturnsToEmo = Template.bind({});

export const VhaCamoToVhaPo = Template.bind({});

export const VhaPoToVisn = Template.bind({});

export const EmoToEducationRpo = Template.bind({});
