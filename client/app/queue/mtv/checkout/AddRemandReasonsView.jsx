import React, { useContext, useEffect, useMemo } from 'react';
import PropTypes from 'prop-types';

import COPY from '../../../../COPY';
import QueueFlowPage from '../../components/QueueFlowPage';
import { MotionToVacateContext } from './MotionToVacateContext';
import { sprintf } from 'sprintf-js';
import { PAGE_TITLES } from '../../constants';
import IssueRemandReasonsOptions from '../../components/IssueRemandReasonsOptions';
import { useDispatch } from 'react-redux';
import { editStagedAppeal, setDecisionOptions, stageAppeal } from '../../QueueActions';

const validateForm = () => true;

export const AddRemandReasonsView = ({ appeal }) => {
  const [ctx, setCtx] = useContext(MotionToVacateContext);
  const dispatch = useDispatch();
  const appealId = appeal.id;

  useEffect(() => {
    // We need to update staged appeal in Redux so existing flow can continue
    dispatch(stageAppeal(appealId));
    dispatch(editStagedAppeal(appealId, { decisionIssues: ctx.decisionIssues }));
    dispatch(setDecisionOptions({ work_product: 'Decision' }));
  }, [appeal, ctx.decisionIssues]);

  const pageTitle = PAGE_TITLES.REMANDS.ATTORNEY;
  const pageSubhead = sprintf(
    COPY.REMAND_REASONS_SCREEN_SUBHEAD_LABEL,
    'select'
  );

  const remandedIssues = useMemo(
    () =>
      ctx.decisionIssues.filter((issue) => issue.disposition === 'remanded'),
    [ctx.decisionIssues]
  );

  const goToNextStep = () => {
    console.log('next step');
  };
  const goToPrevStep = () => null;

  return (
    <QueueFlowPage
      validateForm={validateForm}
      appealId={appeal.externalId}
      getNextStepUrl={() => ctx.getNextUrl('add_decisions')}
      getPrevStepUrl={() => ctx.getPrevUrl('add_decisions')}
      goToNextStep={goToNextStep}
      goToPrevStep={goToPrevStep}
    >
      <h1>{pageTitle}</h1>
      <p>{pageSubhead}</p>
      <hr />
      {remandedIssues.map((issue, idx) => (
        <IssueRemandReasonsOptions
          appealId={appeal.externalId}
          issueId={remandedIssues[idx].id}
          key={`remand-reasons-options-${idx}`}
          // ref={this.getChildRef}
          idx={idx}
        />
      ))}
    </QueueFlowPage>
  );
};

AddRemandReasonsView.propTypes = {
  appeal: PropTypes.object.isRequired,
};
