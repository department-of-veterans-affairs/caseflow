/* eslint-disable max-len */
import React, { useMemo } from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';

import { showSuccessMessage, showErrorMessage } from 'app/queue/uiReducer/uiActions';
import { EditCavcRemandReview } from './editCavcRemandReview';

import { cancel, reset, stepBack } from '../editCavcRemand.slice';
import { getAllTasksForAppeal, appealWithDetailSelector } from 'app/queue/selectors';

import COPY from 'app/../COPY';
import { requestPatch } from '../../uiReducer/uiActions';

export const EditCavcRemandReviewContainer = () => {
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

  const tasksToCancel = allTasks.filter((task) => {
    return (existingValues.cancelTaskIds.includes(task.id));
  });

  const tasksToReActivate = allTasks.filter((task) => {
    return (existingValues.reActivateTaskIds.includes(task.id));
  })

  const { relationships } = useSelector((state) => state.cavcRemand);
  const relationship = useMemo(() => {
    return relationships?.find((rel) => String(rel.value) === String(existingValues.participantId)) ?? null;
  }, [relationships, existingValues?.participantId]);

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

  const buildTaskCreationParameters = () => {
    const taskParams = {};

    return taskParams;
  };

  const handleSubmit = async () => {
    // Here we'll dispatch completeSubstituteAppellant action to submit data from Redux to the API
    const payload = {
      data: {
        judgement_date: existingValues.judgementDate ? existingValues.judgementDate : '',
        mandate_date: existingValues.mandateDate ? existingValues.mandateDate : '',
        source_appeal_id: existingValues.source_appeal_uuid,
        remand_appeal_id: appealId,
        cavc_docket_number: existingValues.docketNumber,
        cavc_judge_full_name: existingValues.judge,
        cavc_decision_type: existingValues.decisionType,
        decision_date: existingValues.decisionDate,
        remand_subtype: existingValues.remandType,
        represented_by_attorney: existingValues.attorney === 'yes',
        decision_issue_ids: existingValues.issueIds,
        federal_circuit: existingValues.federalCircuit,
        instructions: existingValues.instructions,
        substitution_date: existingValues.isAppellantSubstituted === 'true' ? existingValues.substitutionDate : null,
        participant_id: existingValues.isAppellantSubstituted === 'true' ? existingValues.participantId : null,
        is_appellant_substituted: existingValues.isAppellantSubstituted,
        // these are task ids to reopen
        selected_task_ids: existingValues.reActivateTaskIds,
        // these are the task ids to be cancelled
        cancelled_task_ids: existingValues.cancelTaskIds,
        task_params: buildTaskCreationParameters()
      },
    };

    const successMsg = {
      title: COPY.CAVC_REMAND_EDIT_SUCCESS_TITLE,
      detail: COPY.CAVC_REMAND_EDIT_SUCCESS_DETAIL,
    };

    try {
      const res = await dispatch(
        requestPatch(`/appeals/${appealId}/cavc_remand`, payload, successMsg)
      );
      const updatedCavcRemand = res.body.cavc_remand;
      const updatedAppealAttributes = res.body.updated_appeal_attributes;

      // Update Redux
      dispatch(editAppeal(appealId, {
        cavcRemand: updatedCavcRemand,
        appellantSubstitution: updatedAppealAttributes.appellant_substitution,
        appellantIsNotVeteran: updatedAppealAttributes.appellant_is_not_veteran,
        appellantFullName: updatedAppealAttributes.appellant_full_name,
        appellantAddress: updatedAppealAttributes.appellant_address,
        appellantRelationship: updatedAppealAttributes.appellant_relationship,
        appellantType: updatedAppealAttributes.appellant_type,
      }));
      // Redirect back to case details for remand appeal
      // EditCavcTodo: Force a refresh in case issue selection changed
      history.push(`/queue/appeals/${appealId}`);

    } catch (error) {
      dispatch(
        showErrorMessage({
          title: 'Error',
          detail: JSON.parse(error.message).errors[0].detail,
        })
      );
    }
  };

  return (
    <EditCavcRemandReview
      tasksToReActivate={tasksToReActivate}
      tasksToCancel={tasksToCancel}
      existingValues={existingValues}
      appeal={appeal}
      relationship={relationship}
      onBack={handleBack}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
    />
  );
};
