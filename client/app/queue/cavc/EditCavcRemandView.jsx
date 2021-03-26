import React, { useMemo } from 'react';

import { useParams } from 'react-router';
import { useSelector } from 'react-redux';

import { appealWithDetailSelector } from 'app/queue/selectors';
import { getSupportedDecisionTypes, getSupportedRemandTypes } from './utils';
import { EditCavcRemandForm } from './EditCavcRemandForm';

export const EditCavcRemandView = () => {
  const { appealId } = useParams();
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
      attorney: cavcRemand.represented_by_attorney,
    };
  }, [cavcRemand]);

  const handleCancel = () => {};
  const handleSubmit = () => {};

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
