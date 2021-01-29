import React, { useContext, useMemo, useState } from 'react';
import PropTypes from 'prop-types';

import COPY from 'app/../COPY';
import QueueFlowPage from 'app/queue/components/QueueFlowPage';
import { MotionToVacateContext } from './MotionToVacateContext';
import { sprintf } from 'sprintf-js';
import { PAGE_TITLES } from '../../constants';

import { IssueRemandReasonsForm } from 'app/queue/components/remandReasons/IssueRemandReasonsForm';

const validateForm = () => true;

export const AddRemandReasonsView = ({ appeal }) => {
  const [ctx] = useContext(MotionToVacateContext);
  const [highlighting, setHighlighting] = useState({});
  const [numIssuesVisible, setNumIssuesVisible] = useState(1);

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

  const visibleIssues = useMemo(
    () => remandedIssues.slice(0, numIssuesVisible),
    [remandedIssues, numIssuesVisible]
  );

  const handleIssueReasonChange = (issue, reasons) => issue.remand_reasons = reasons;

  const goToNextStep = () => {
    setHighlighting({ ...highlighting, [numIssuesVisible - 1]: true });

    if (numIssuesVisible < remandedIssues.length) {
      setNumIssuesVisible(numIssuesVisible + 1);

      return false;
    }

    return true;
  };

  return (
    <QueueFlowPage
      validateForm={validateForm}
      appealId={appeal.externalId}
      getNextStepUrl={() => ctx.getNextUrl('add_decisions')}
      getPrevStepUrl={() => ctx.getPrevUrl('add_decisions')}
      goToNextStep={goToNextStep}
    >
      <h1>{pageTitle}</h1>
      <p>{pageSubhead}</p>
      <hr />
      {visibleIssues.map((issue, idx) => (
        <IssueRemandReasonsForm
          issue={issue}
          issueNumber={idx + 1}
          issueTotal={remandedIssues.length}
          highlight={highlighting[idx]}
          key={`remand-reasons-options-${idx}`}
          certificationDate={appeal.certificationDate}
          onChange={(reasons) => handleIssueReasonChange(issue, reasons)}
          values={issue.remandReasons ?? []}
        />
      ))}
    </QueueFlowPage>
  );
};

AddRemandReasonsView.propTypes = {
  appeal: PropTypes.object.isRequired,
};
