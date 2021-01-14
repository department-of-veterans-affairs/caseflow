import React from 'react';
import { useSelector } from 'react-redux';
import { DocketSwitchAddTaskForm } from './DocketSwitchAddTaskForm';
import { appealWithDetailSelector, getAllTasksForAppeal } from '../../selectors';
import { useHistory, useParams } from 'react-router';

export const DocketSwitchAddTaskContainer = () => {
  const { appealId } = useParams();
  const { goBack } = useHistory();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const tasks = useSelector((state) =>
    getAllTasksForAppeal(state, { appealId })
  );

  const docketType = useSelector((state) =>
    state.docketSwitch.formData.docketType);

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
        docketName={appeal.docketName}
        taskListing={tasks}
        onBack={handleBack}
        docketType={docketType}
      />
    </>
  );
};
