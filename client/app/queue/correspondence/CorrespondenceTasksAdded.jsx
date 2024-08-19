import React from 'react';
import PropTypes from 'prop-types';
import CaseDetailsLink from '../CaseDetailsLink';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import CorrespondenceCaseTimeline from './CorrespondenceCaseTimeline';

const CorrespondenceTasksAdded = (props) => {
  const veteranName = props.correspondence.veteran_name;
  const veteranFullName = `${veteranName.first_name} ${veteranName.middle_initial} ${veteranName.last_name}`;

  return (
    <>
      <div className="tasks-added-container">
        <div className="correspondence-tasks-added ">
          <div className="corr-tasks-added-col first-row">
            <p className="task-added-header">Docket number</p>
            <span className="case-details-badge">
              <DocketTypeBadge name={props.task_added.appealType} />
              <CaseDetailsLink
                appeal={{ externalId: props.task_added.appealUuid }}
                getLinkText={() => props.task_added.docketNumber}
                task={props.task_added}

                linkOpensInNewTab
              />
            </span>

          </div>
          <div className="corr-tasks-added-col">
            <p className="task-added-header">Appellant name</p>
            <p>{veteranFullName}</p>
          </div>
          <div className="corr-tasks-added-col">
            <p className="task-added-header">Appeal stream type</p>
            <p>{props.task_added.streamType}</p>
          </div>
          <div className="corr-tasks-added-col">
            <p className="task-added-header">Number of issues</p>
            <p>{props.task_added.numberOfIssues}</p>
          </div>
          <div className="corr-tasks-added-col">
            <p className="task-added-header">Status</p>
            <p>{props.task_added.status}</p>
          </div>
          <div className="corr-tasks-added-col">
            <p className="task-added-header">Added to</p>
            <p>{props.task_added.assignedTo ? props.task_added.assignedTo.name : ''}</p>
          </div>

        </div >
        <div className="tasks-added-details">
          <span className="tasks-added-text">Tasks added to appeal</span>
          <div >
            <CorrespondenceCaseTimeline
              organizations={props.organizations}
              userCssId="INBOUND_OPS_TEAM_ADMIN_USEkR"
              correspondence={props.task_added.correspondence}
              tasksToDisplay={(props.task_added.taskAddedData)}
            />
          </div>
        </div>
      </div>
    </>
  );
};

CorrespondenceTasksAdded.propTypes = {
  correspondence: PropTypes.object,
  task_added: PropTypes.object,
  organizations: PropTypes.array

};

export default CorrespondenceTasksAdded;
