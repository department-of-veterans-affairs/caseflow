import React from 'react';

import CancelTaskModal from './CancelTaskModal';
import { appealData, changeHearingRequestTypeTask } from 'test/data';
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
        {
          ...changeHearingRequestTypeTask,
          availableActions: [
            {
              label: 'Cancel convert hearing to virtual',
              func: 'cancel_convert_hearing_request_type_data',
              value: 'modal/cancel_task',
              data: {
                redirect_after: '/queue/appeals/1986897',
                modal_title: 'Cancel convert hearing to virtual task',
                message_title: 'Task for Merlin V Langworth\'s case has been cancelled',
                message_detail: 'You have successfully cancelled the convert hearing to virtual task',
                show_instructions: false
              }
            }
          ]
        }
      ]
    },
    // The test relies on `props.match` to match against one of the available actions.
    route: TASK_ACTIONS.CANCEL_CONVERT_HEARING_REQUEST_TYPE_TO_VIRTUAL.value
  },
  componentArgs: {
    taskId: changeHearingRequestTypeTask.uniqueId
  }
};
