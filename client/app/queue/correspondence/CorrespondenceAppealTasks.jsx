import React from 'react';
import PropTypes from 'prop-types';
import CaseDetailsLink from '../CaseDetailsLink';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import { appealWithDetailSelector, taskSnapshotTasksForAppeal } from '../selectors';
import { useSelector, connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import TaskRows from '../components/TaskRows';
import Alert from '../../components/Alert';
import {
  setWaiveEvidenceAlertBanner
} from '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';

const CorrespondenceAppealTasks = (props) => {
  const {
    waiveEvidenceAlertBanner,
  } = { ...props };

  const veteranFullName = props.correspondence.veteranFullName;
  const appealId = props.appeal.external_id;
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const tasks = useSelector((state) =>
    taskSnapshotTasksForAppeal(state, { appealId })
  );

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

        </div>
        <div className="tasks-added-waive-banner-alert">
          <div className="waive-banner-alert">
            {appeal &&
            waiveEvidenceAlertBanner &&
            waiveEvidenceAlertBanner.message &&
            waiveEvidenceAlertBanner.appealId &&
            appeal.id &&
            waiveEvidenceAlertBanner.appealId.toString() === appeal.id.toString() && (
                <Alert
                  type={waiveEvidenceAlertBanner.type}
                  message={waiveEvidenceAlertBanner.message}
                  scrollOnAlert={false}
                />
              )}
          </div>
        </div>
        <div className="tasks-added-details">
          <span className="tasks-added-text">Tasks added to appeal</span>
          <div>
            <TaskRows
              key={appeal.id.toString()}
              appeal={appeal}
              taskList={tasks}
              timeline={false}
              editNodDateEnabled={false}
              hideDropdown
              waivableUser={props.waivableUser}
            />
          </div>
        </div>
      </div>
    </>
  );
};

CorrespondenceAppealTasks.propTypes = {
  correspondence: PropTypes.object,
  task_added: PropTypes.object,
  organizations: PropTypes.array,
  userCssId: PropTypes.string,
  appeal: PropTypes.object,
  waivableUser: PropTypes.bool,
  setWaiveEvidenceAlertBanner: PropTypes.func
};

const mapStateToProps = (state) => ({
  waiveEvidenceAlertBanner: state.correspondenceDetails.waiveEvidenceAlertBanner,
});


const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    setWaiveEvidenceAlertBanner,
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CorrespondenceAppealTasks);
