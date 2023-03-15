import React, { useMemo } from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';
import { parseISO } from 'date-fns';

import {
  appealWithDetailSelector,
  getAllTasksForAppeal,
} from 'app/queue/selectors';
import { EditCavcRemandTasksForm } from './editCavcRemandTasksForm';

import {
  cancel,
  stepBack,
  stepForward,
  updateData,
} from '../editCavcRemand.slice';
import {
  editCavcRemandSubstitutionCancelOrCompletedTaskDataForUi,
  editCavcRemandSubstitutionOpenTaskDataForUi
} from './utils';

export const EditCavcRemandTasksView = () => {
  const { appealId } = useParams();
  const dispatch = useDispatch();
  const history = useHistory();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const { formData: existingValues } = useSelector(
    (state) => state.cavcRemand
  );

  const allTasks = useSelector((state) =>
    getAllTasksForAppeal(state, { appealId })
  );

  const activeTasks = useMemo(() => {
    return editCavcRemandSubstitutionOpenTaskDataForUi({ taskData: allTasks });
  }, [allTasks]);

  const cancelTaskIds = activeTasks.map( (task) => task.id );

  const cancelledOrCompletedTasks = useMemo(() => {
    return editCavcRemandSubstitutionCancelOrCompletedTaskDataForUi({ taskData: allTasks });
  }, [allTasks]);

  const reActivateTaskIds = cancelledOrCompletedTasks.map( (task) => task.id );
  // These values will be used in the "key details" section
  const nodDate = useMemo(() => parseISO(appeal.nodDate), [appeal.nodDate]);
  const dateOfDeath = useMemo(() => {
    const dod = appeal.veteranDateOfDeath;

    return dod ? parseISO(dod) : null;
  }, [appeal.veteranInfo]);

  const substitutionDate = useMemo(
    () => parseISO(existingValues.substitutionDate),
    [existingValues.substitutionDate]
  );

  const handleBack = () => {
    dispatch(stepBack());
    history.goBack();
  };
  const handleCancel = () => {
    // Reset Redux store
    dispatch(cancel());

    // Redirect to Case Details page
    history.push(`/queue/appeals/${appealId}`);
  };
  const handleSubmit = async (formData) => {
    // Here we'll dispatch updateData action to update Redux store with our form data
    dispatch(
      updateData({
        formData: {
          ...existingValues,
          reActivateTaskIds: reActivateTaskIds ? reActivateTaskIds : [],
          cancelTaskIds: cancelTaskIds ? cancelTaskIds : []
        }
      })
    );

    // Advance progressbar
    dispatch(stepForward());
    // Move to next page
    history.push(`/queue/appeals/${appealId}/edit_cavc_remand/review`);
  };

  return (
    <EditCavcRemandTasksForm
      appealId={appealId}
      existingValues={existingValues}
      nodDate={nodDate}
      dateOfDeath={dateOfDeath}
      substitutionDate={substitutionDate}
      cancelledTasks={cancelledOrCompletedTasks}
      activeTasks={activeTasks}
      onBack={handleBack}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
    />
  );
};
