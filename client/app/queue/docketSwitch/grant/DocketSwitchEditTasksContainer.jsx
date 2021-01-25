import React, { useMemo } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { DocketSwitchEditTasksForm } from './DocketSwitchEditTasksForm';
import {
  appealWithDetailSelector,
  getAllTasksForAppeal,
} from '../../selectors';
import { useHistory, useParams } from 'react-router';

import { cancel, stepForward, updateDocketSwitch } from '../docketSwitchSlice';

export const DocketSwitchEditTasksContainer = () => {
  const { appealId } = useParams();
  const { goBack, push } = useHistory();
  const dispatch = useDispatch();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const tasks = useSelector((state) =>
    getAllTasksForAppeal(state, { appealId })
  );

  const docketType = useSelector(
    (state) => state.docketSwitch.formData.docketType
  );

  const handleCancel = () => {
    // Clear Redux store
    dispatch(cancel());

    // Return to case details page
    push(`/queue/appeals/${appealId}`);
  };

  const handleBack = () => goBack();

  const switchableTasks = useMemo(() => {
    return tasks.filter((task) => task.canMoveOnDocketSwitch);
  }, [tasks]);

  const handleSubmit = (formData) => {
    // Add stuff to redux store
    dispatch(updateDocketSwitch(formData));

    // // Move to next step
    dispatch(stepForward());
  };

  return (
    <>
      <DocketSwitchEditTasksForm
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
