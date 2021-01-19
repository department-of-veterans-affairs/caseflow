import React, { useMemo } from 'react';
import { useSelector } from 'react-redux';
import { DocketSwitchAddTaskForm } from './DocketSwitchAddTaskForm';
import { appealWithDetailSelector, getAllTasksForAppeal, taskById } from '../../selectors';
import { useHistory, useParams, useRouteMatch } from 'react-router';

export const DocketSwitchAddTaskContainer = () => {
  const { appealId, taskId } = useParams();
  const { goBack } = useHistory();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const tasks = useSelector((state) =>
    getAllTasksForAppeal(state, { taskId })
  );

  const docketType = useSelector((state) =>
    state.docketSwitch.formData.docketType);

  const handleCancel = () => {
    // Add code to clear docketSwitch redux store
    // You can utilize useHistory() react-router hook to go back to the case details page
  };

  const handleBack = () => goBack();

  const switchableTasks = useMemo(() => {
    return tasks.filter((task) => task.canMoveOnDocketSwitch);
  });

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
        taskListing={switchableTasks}
        onBack={handleBack}
        docketType={docketType}
      />
    </>
  );
};
