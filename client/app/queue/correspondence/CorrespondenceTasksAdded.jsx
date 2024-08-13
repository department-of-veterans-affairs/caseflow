import React from 'react';
import PropTypes from 'prop-types';
import CaseDetailsLink from '../CaseDetailsLink';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import { ExternalLinkIcon } from '../../components/icons/ExternalLinkIcon';
import CorrespondenceCaseTimeline from './CorrespondenceCaseTimeline';

const CorrespondenceTasksAdded = (props) => {

  const veteranName = props.correspondence.veteran_name;
  const veteranFullName = `${veteranName.first_name} ${veteranName.middle_initial} ${veteranName.last_name}`;
  // console.log(veteranFullName)
  console.log(props)
  return (
    <>
      <div className="tasks-added-container">
        <div className="correspondence-tasks-added ">
          <div className="corr-tasks-added-col first-row">
            <p className="task-added-header">Docket number</p>
            <span className="case-details-badge">
              <DocketTypeBadge name="test" />
              <CaseDetailsLink
                appeal={props.correspondence}
                getLinkText={() => props.task_added.docketNumber}
                task={{}}
              />
              <span className="link-icon-container"><ExternalLinkIcon color="blue" /> </span>
            </span>

          </div>
          <div className="corr-tasks-added-col">
            <p className="task-added-header">Appellant name</p>
            <p>{veteranFullName}</p>
          </div>
          <div className="corr-tasks-added-col">
            <p className="task-added-header">Appeal stream type</p>
            <p>{props.task_added.stream_type}</p>
          </div>
          <div className="corr-tasks-added-col">
            <p className="task-added-header">Number of issues</p>
            <p>{props.task_added.number_of_issues}</p>
          </div>
          <div className="corr-tasks-added-col">
            <p className="task-added-header">Status</p>
            <p>{props.task_added.status}</p>
          </div>
          <div className="corr-tasks-added-col">
            <p className="task-added-header">Added to</p>
            <p>{props.task_added.assigned_to}</p>
          </div>

        </div >
        <div className="tasks-added-details">
          <span className="tasks-added-text">Tasks added to appeal</span>

          <CorrespondenceCaseTimeline
            organizations={['TEST']}
            userCssId="INBOUND_OPS_TEAM_ADMIN_USER"
            correspondence={props.task_added.correspondence}
            tasksToDisplay={props.correspondence.tasksAddedToAppeal}
          />
        </div>
      </div>
    </>
  );
};

CorrespondenceTasksAdded.propTypes = {
  correspondence: PropTypes.object,
  task_added: PropTypes.object,

};

export default CorrespondenceTasksAdded;
