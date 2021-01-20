import React, { useMemo } from 'react';
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
  };

  const handleBack = () => goBack();

  const switchableTasks = useMemo(() => {
    return tasks.filter((task) => task.canMoveOnDocketSwitch);
  }, [tasks]);

  const handleSubmit = () => {
    // Add stuff to redux store
  };

  return (
    <>
      <DocketSwitchAddTaskForm
        onCancel={handleCancel}
        onSubmit={handleSubmit}
        docketFrom={appeal.docketName}
        taskListing={switchableTasks}
        onBack={handleBack}
        docketTo={docketType}
      />
    </>
  );
};
