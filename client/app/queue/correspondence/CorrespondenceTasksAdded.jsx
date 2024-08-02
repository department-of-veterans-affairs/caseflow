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
        <p>{props.task_added.appellant_name}</p>
      </div>
      <div className="corr-tasks-added-col">
        <p>Appeal stream type</p>
        <p>{props.task_added.stream_type}</p>
      </div>
      <div className="corr-tasks-added-col">
        <p>Number of issues</p>
        <p>{props.task_added.number_of_issues}</p>
      </div>
      <div className="corr-tasks-added-col">
        <p>Status</p>
        <p>{props.task_added.status}</p>
      </div>
      <div className="corr-tasks-added-col">
        <p>Added to</p>
        <p>{props.task_added.assigned_to}</p>
      </div>

    </div>
  );
};

export default CorrespondenceTasksAdded;
