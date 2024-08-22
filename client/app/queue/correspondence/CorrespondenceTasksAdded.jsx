import React from 'react';
import PropTypes from 'prop-types';
import CaseDetailsLink from '../CaseDetailsLink';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import CorrespondenceCaseTimeline from './CorrespondenceCaseTimeline';

const CorrespondenceTasksAdded = (props) => {
  const veteranFullName = props.correspondence.veteranFullName;

  return (
    <>
      <div className="tasks-added-container">
        <div className="correspondence-tasks-added ">
          <div className="corr-tasks-added-col first-row">
            <p className="task-added-header">DOCKET NUMBER</p>
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
            <p className="task-added-header">APPELLANT NAME</p>
            <p>{veteranFullName}</p>
          </div>
          <div className="corr-tasks-added-col">
            <p className="task-added-header">APPEAL STREAM TYPE</p>
            <p>{props.task_added.streamType}</p>
          </div>
          <div className="corr-tasks-added-col">
            <p className="task-added-header">NUMBER OF ISSUES</p>
            <p>{props.task_added.numberOfIssues}</p>
          </div>
          <div className="corr-tasks-added-col">
            <p className="task-added-header">STATUS</p>
            <p>{props.task_added.status}</p>
          </div>
          <div className="corr-tasks-added-col">
            <p className="task-added-header">ASSIGNED TO</p>
            <p>{props.task_added.assignedTo ? props.task_added.assignedTo.name : ''}</p>
          </div>

        </div >
        <div className="tasks-added-details">
          <span className="tasks-added-text">Tasks added to appeal</span>
          <div >
            <CorrespondenceCaseTimeline
              organizations={props.organizations}
              userCssId={props.userCssId}
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
  organizations: PropTypes.array,
  userCssId: PropTypes.string,

};

export default CorrespondenceTasksAdded;
