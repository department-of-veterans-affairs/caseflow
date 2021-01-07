import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { stepForward } from '../docketSwitchSlice';
import { DocketSwitchAddTaskForm } from './DocketSwitchAddTaskForm';
import { appealWithDetailSelector, getAllTasksForAppeal } from '../../selectors';
import { useHistory, useParams } from 'react-router';

export const DocketSwitchAddTaskContainer = () => {
  const dispatch = useDispatch();
  const { appealId, taskId } = useParams();
  const { goBack, push } = useHistory();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const tasks = useSelector((state) =>
    getAllTasksForAppeal(state, { appealId })
  );

  const handleCancel = () => {
    // Add code to clear docketSwitch redux store
    // You can utilize useHistory() react-router hook to go back to the case details page
  };

  const handleCancelModal = () => goBack();

  const handleSubmit = () => {
    // Add stuff to redux store

    // Call stepForward redux action
    dispatch(stepForward());

    // Move to next step
  };

  return (
    <>
      <DocketSwitchAddTaskForm
        onCancel={handleCancel}
        onSubmit={handleSubmit}
        docketName={appeal.docketName}
        taskListing={tasks}
        closeModal={ handleCancelModal}
      />
    </>
  );
};
