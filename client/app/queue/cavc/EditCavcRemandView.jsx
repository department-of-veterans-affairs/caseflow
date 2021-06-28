import React, { useMemo } from 'react';

import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';

import COPY from 'app/../COPY';
import { appealWithDetailSelector } from 'app/queue/selectors';
import { getSupportedDecisionTypes, getSupportedRemandTypes } from './utils';
import { EditCavcRemandForm } from './EditCavcRemandForm';
import { requestPatch, showErrorMessage } from 'app/queue/uiReducer/uiActions';
import { editAppeal } from '../QueueActions';

export const EditCavcRemandView = () => {
  /* eslint-disable camelcase */
  const { appealId } = useParams();
  const dispatch = useDispatch();
  const history = useHistory();
  const cavcAppeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );
  const { cavcRemand } = cavcAppeal;

  const featureToggles = useSelector((state) => state.ui.featureToggles);

  const supportedDecisionTypes = getSupportedDecisionTypes(featureToggles);
  const supportedRemandTypes = getSupportedRemandTypes(featureToggles);

  const existingValues = useMemo(() => {
    return {
      decisionType: cavcRemand.cavc_decision_type,
      docketNumber: cavcRemand.cavc_docket_number,
      judge: cavcRemand.cavc_judge_full_name,
      decisionDate: cavcRemand.decision_date,
      issueIds: cavcRemand.decision_issue_ids,
      federalCircuit: cavcRemand.federal_circuit,
      instructions: cavcRemand.instructions,
      judgementDate: cavcRemand.judgement_date,
      mandateDate: cavcRemand.mandate_date,
      remandType: cavcRemand.remand_subtype,
      attorney: cavcRemand.represented_by_attorney ? 'yes' : 'no',
      remandDatesProvided: (cavcRemand.judgement_date || cavcRemand.mandate_date) ? 'yes' : 'no',
      remand_appeal_id: cavcRemand.remand_appeal_uuid,
    };
  }, [cavcRemand]);

  const handleCancel = () => history.push(`/queue/appeals/${appealId}`);

  const handleSubmit = async (formData) => {
    const payload = {
      data: {
        judgement_date: formData.judgementDate ? formData.judgementDate : '',
        mandate_date: formData.mandateDate ? formData.mandateDate : '',
        source_appeal_id: cavcRemand.source_appeal_uuid,
        remand_appeal_id: appealId,
        cavc_docket_number: formData.docketNumber,
        cavc_judge_full_name: formData.judge,
        cavc_decision_type: formData.decisionType,
        decision_date: formData.decisionDate,
        remand_subtype: formData.remandType,
        represented_by_attorney: formData.attorney === 'yes',
        decision_issue_ids: formData.issueIds,
        federal_circuit: formData.federalCircuit,
        instructions: formData.instructions,
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

      // Update Redux
      dispatch(editAppeal(appealId, { cavcRemand: updatedCavcRemand }));

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
    <EditCavcRemandForm
      decisionIssues={cavcRemand?.source_decision_issues}
      existingValues={existingValues}
      supportedDecisionTypes={supportedDecisionTypes}
      supportedRemandTypes={supportedRemandTypes}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
    />
  );
};
