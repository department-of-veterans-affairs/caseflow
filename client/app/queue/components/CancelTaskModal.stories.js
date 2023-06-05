import React from 'react';

import CancelTaskModal from './CancelTaskModal';
import {
  appealData,
  changeHearingRequestTypeTask,
  changeHearingRequestTypeTaskCancelAction
} from 'test/data';
import { queueWrapper as Wrapper } from '../../../test/data/stores/queueStore';
import TASK_ACTIONS from '../../../constants/TASK_ACTIONS';

export default {
  title: 'Queue/Components/CancelTaskModal',
  component: CancelTaskModal,
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
      <CancelTaskModal
        {...componentArgs}
      />
    </Wrapper>
  );
};

export const CancelChangeHearingRequestTypeTask = Template.bind({});
CancelChangeHearingRequestTypeTask.args = {
  storeArgs: {
    queue: {
      tasks: [
        changeHearingRequestTypeTaskCancelAction
      ]
    },
    // The test relies on `props.match` to match against one of the available actions.
    route: TASK_ACTIONS.CANCEL_CONVERT_HEARING_REQUEST_TYPE_TO_VIRTUAL.value
  },
  componentArgs: {
    taskId: changeHearingRequestTypeTask.uniqueId
  }
};
