import React from 'react';
import { mount } from 'enzyme';

import { TextareaField } from 'app/components/TextareaField';
import CancelTaskModal from 'app/queue/components/CancelTaskModal';
import { queueWrapper } from '../../../data/stores/queueStore';
import {
  changeHearingRequestTypeTask,
  changeHearingRequestTypeTaskCancelAction
} from '../../../data/tasks';
import TASK_ACTIONS from 'constants/TASK_ACTIONS';

const requestPatchMock = jest.fn();

describe('CancelTaskModal', () => {
  test('for cancel change hearing request type action', () => {
    const cancelModal = mount(
      <CancelTaskModal
        requestPatch={requestPatchMock}
        taskId={changeHearingRequestTypeTask.uniqueId}
        match={{path: TASK_ACTIONS.CANCEL_CONVERT_HEARING_REQUEST_TYPE_TO_VIRTUAL.value}}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: {
          queue: {
            tasks: [
              {
                ...changeHearingRequestTypeTask,
                availableActions: [
                  changeHearingRequestTypeTaskCancelAction
                ]
              }
            ]
          },
          route: TASK_ACTIONS.CANCEL_CONVERT_HEARING_REQUEST_TYPE_TO_VIRTUAL.value
        }
      }
    );

    expect(cancelModal).toMatchSnapshot();
    expect(cancelModal.find(TextareaField)).toHaveLength(0);
  });
});
