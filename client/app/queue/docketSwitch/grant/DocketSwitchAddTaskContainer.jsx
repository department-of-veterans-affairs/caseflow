import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { DocketSwitchAddTaskForm } from './DocketSwitchAddTaskForm';
import { appealWithDetailSelector, getAllTasksForAppeal } from '../../selectors';
import { useHistory, useParams,  useRouteMatch } from 'react-router';
import { updateDocketSwitch } from '../docketSwitchSlice'

export const DocketSwitchAddTaskContainer = () => {
  const dispatch = useDispatch();
  const { appealId } = useParams();
  const { goBack, push } = useHistory();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const tasks = useSelector((state) =>
    getAllTasksForAppeal(state, { appealId })
  );

  const docketType = useSelector((state) => 
    state.docketSwitch.formData.formData.docketType);

  const handleCancel = () => {
    // Add code to clear docketSwitch redux store
    // You can utilize useHistory() react-router hook to go back to the case details page
  };

  const handleBack = () => goBack();

  const handleSubmit = () => {
    // Add stuff to redux store

    // Call stepForward redux action
    // dispatch(stepForward());

    // Move to next step
  };

  return (
    <>
      <DocketSwitchAddTaskForm
        onCancel={handleCancel}
        onSubmit={handleSubmit}
        appeal={appeal}
        taskListing={tasks}
        onBack={handleBack}
        docketType={docketType}
      />
    </>
  );
};
