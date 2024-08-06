import React from 'react';
import CaseDetailsLink from '../CaseDetailsLink';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import { ExternalLinkIcon } from '../../components/icons/ExternalLinkIcon';
import CorrespondenceCaseTimeline from './CorrespondenceCaseTimeline';

const CorrespondenceTasksAdded = (props) => {
  console.log(props.task_added);

  return (
    <>
      <div className="tasks-added-container">
        <div className="correspondence-tasks-added ">
          <div className="corr-tasks-added-col first-row">
            <p>Docket number</p>
            <span className="case-details-badge">
              <DocketTypeBadge name="test" />
              <CaseDetailsLink appeal={props.correspondence} getLinkText={() => props.task_added.docket_num} task={{}} userRole="red" />
              <span className='link-icon-container'><ExternalLinkIcon color="blue" /> </span>
            </span>

          </div>
          <div className="corr-tasks-added-col">
            <p>Appellant name</p>
            {/* <p>{props.correspondence.veteran_name}</p> */}
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
        <span className="tasks-added-text">Tasks added to appeal</span>

        <CorrespondenceCaseTimeline
          organizations={['TEST']}
          userCssId="INBOUND_OPS_TEAM_ADMIN_USER"
          correspondence={props.task_added.corr}
          tasksToDisplay={props.correspondence.tasksAddedToAppeal}
        />
      </div>
    </>
  );
};

export default CorrespondenceTasksAdded;
