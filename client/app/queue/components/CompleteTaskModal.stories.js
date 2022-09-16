import React from 'react';

import CompleteTaskModal from './CompleteTaskModal';
import { queueWrapper as Wrapper } from '../../../test/data/stores/queueStore';

export default {
  title: 'Queue/Components/Task Action Modals/CompleteTaskModal',
  component: CompleteTaskModal,
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
      <CompleteTaskModal
        {...componentArgs}
      />
    </Wrapper>
  );
};

export const VhaCamoToBoardIntake = Template.bind({});

export const VhaPoToVhaCamo = Template.bind({});

export const VhaCaregiverSupportProgramToBoardIntakeForReview = Template.bind({});

export const VhaCaregiverSupportProgramReturnToBoardIntake = Template.bind({});

export const EmoToBoardIntakeForReview = Template.bind({});

export const EmoReturnToBoardIntake = Template.bind({});

export const EduRpoToBoardIntakeForReview = Template.bind({});


