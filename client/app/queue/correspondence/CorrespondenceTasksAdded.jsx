import React from 'react';
import CaseDetailsLink from '../CaseDetailsLink';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import { ExternalLinkIcon } from '../../components/icons/ExternalLinkIcon';

const CorrespondenceTasksAdded = (props) => {
  return (
    <div className="correspondence-tasks-added ">
      <div className="corr-tasks-added-col first-row">
        <p>Docket number</p>
        <span className="case-details-badge">
          <DocketTypeBadge name="test" />
          <CaseDetailsLink appeal={props.correspondence} task={{}} userRole="test" />
          <ExternalLinkIcon color="blue" />
        </span>

      </div>
      <div className="corr-tasks-added-col">
        <p>Appellant name</p>
        <p>test</p>
      </div>
      <div className="corr-tasks-added-col">
        <p>Appeal stream type</p>
        <p>test</p>
      </div>
      <div className="corr-tasks-added-col">
        <p>Number of issues</p>
        <p>test</p>
      </div>
      <div className="corr-tasks-added-col">
        <p>Status</p>
        <p>test</p>
      </div>
      <div className="corr-tasks-added-col">
        <p>Added to</p>
        <p>test</p>
      </div>

    </div>
  );
};

export default CorrespondenceTasksAdded;
