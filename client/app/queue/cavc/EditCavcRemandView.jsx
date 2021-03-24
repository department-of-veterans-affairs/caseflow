import React from 'react';

import { useParams } from 'react-router';
import { useSelector } from 'react-redux';

import { appealWithDetailSelector } from 'app/queue/selectors';
import { getSupportedDecisionTypes, getSupportedRemandTypes } from './utils';
import { EditCavcRemandForm } from './EditCavcRemandForm';

export const EditCavcRemandView = () => {
  const { appealId } = useParams();
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );
  const featureToggles = useSelector((state) => state.featureToggles);

  const supportedDecisionTypes = getSupportedDecisionTypes(featureToggles);
  const supportedRemandTypes = getSupportedRemandTypes(featureToggles);

  const handleCancel = () => {};
  const handleSubmit = () => {};

  return (
    <EditCavcRemandForm
      decisionIssues={appeal.decisionIssues}
      supportedDecisionTypes={supportedDecisionTypes}
      supportedRemandTypes={supportedRemandTypes}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
    />
  );
};
