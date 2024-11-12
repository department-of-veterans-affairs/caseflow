import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import CaseDetailsLink from '../CaseDetailsLink';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import { appealWithDetailSelector, taskSnapshotTasksForAppeal } from '../selectors';
import { useSelector, useDispatch, connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import TaskRows from '../components/TaskRows';
import Alert from '../../components/Alert';
import {
  setWaiveEvidenceAlertBanner,
  updateExpandedLinkedAppeals
} from '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';
import Button from '../../components/Button';
import AddRelatedTaskModalCorrespondenceDetails from
  './intake/components/TasksAppeals/AddRelatedTaskModalCorrespondenceDetails';

const CorrespondenceAppealTasks = (props) => {
  const {
    waiveEvidenceAlertBanner,
    expandedLinkedAppeals
  } = { ...props };

  const dispatch = useDispatch();
  const veteranFullName = props.correspondence.veteranFullName;
  const appealId = props.appealUuid;
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const tasks = useSelector((state) =>
    taskSnapshotTasksForAppeal(state, { appealId })
  );

  const [isLinkedAppealExpanded, setIsLinkedAppealExpanded] = useState(props.expandedLinkedAppeals.includes(appealId));

  const toggleLinkedAppealSection = () => {
    setIsLinkedAppealExpanded(!isLinkedAppealExpanded);
    dispatch(updateExpandedLinkedAppeals(expandedLinkedAppeals, appealId));
  };

  useEffect(() => {
    if (
      waiveEvidenceAlertBanner?.message &&
      waiveEvidenceAlertBanner?.appealId?.toString() === appeal?.id?.toString()
    ) {

      dispatch(updateExpandedLinkedAppeals(expandedLinkedAppeals, appealId));

    }
  }, [waiveEvidenceAlertBanner, appeal]);

  const [isAddTaskModalOpen, setIsTaskModalOpen] = useState(false);

  const handleAddTaskModalOpen = () => {
    setIsTaskModalOpen(true);
  };

  const handleAddTaskModalClose = () => {
    setIsTaskModalOpen(false);
  };

  const renderTaskButton = () => {
    return (
      <Button
        type="button"
        onClick={handleAddTaskModalOpen}
        name="addTaskOpen"
        classNames="usa-button-secondary tasks-added-button-spacing"
      >
        + Add task
      </Button>
    );
  };

  const renderTaskRows = () => {
    return (
      <TaskRows
        appeal={appeal}
        taskList={tasks}
        timeline={false}
        editNodDateEnabled={false}
        hideDropdown
        waivableUser={props.waivableUser}
      />
    );
  };

  const renderTaskSectionByCount = () => {
    if (tasks.length === 0) {
      return (
        <div className="left-section">
          <div className="tasks-added-text-alternate">There are no tasks on this appeal.
            {props.waivableUser && renderTaskButton()}
          </div>
        </div>
      );
    } else if (tasks.length < 4) {
      return (
        <div className="left-section">
          <span className="tasks-added-text-second-alternate">Tasks added to appeal
            {props.waivableUser && renderTaskButton()}</span>
          {renderTaskRows()}
        </div>
      );
    }

    return (
      <div className="left-section">
        <span className="tasks-added-text">Tasks added to appeal</span>
        {renderTaskRows()}
      </div>
    );
  };

  return (
    <>
      <div className="correspondence-existing-appeals">
        <div className="left-section">
          <h2>Linked appeal:</h2>
          <div className="case-details-header-badge">
            <DocketTypeBadge name={props.task_added.appealType} />
            <CaseDetailsLink
              appeal={props.task_added?.appealUuid ?
                { externalId: props.task_added?.appealUuid } : { externalId: props.task_added?.externalId }}
              getLinkText={() => props.task_added.docketNumber}
              task={props.task_added}
              linkOpensInNewTab
            />
          </div>
          <div className="number-of-issues-header">
            Number of issues:
            <span>{props.task_added.numberOfIssues}</span>
          </div>
        </div>
        <div className="toggleButton-plus-or-minus">
          <Button
            onClick={() => toggleLinkedAppealSection()}
            linkStyling
            aria-label="Toggle section"
            aria-expanded={isLinkedAppealExpanded}
          >
            {isLinkedAppealExpanded ? '_' : <span className="plus-symbol">+</span>}
          </Button>
        </div>
      </div>
      {isLinkedAppealExpanded && (
        <div className="tasks-added-container">
          <div className="correspondence-tasks-added ">
            <div className="corr-tasks-added-col first-row">
              <p className="task-added-header">DOCKET NUMBER</p>
              <span className="case-details-badge">
                <DocketTypeBadge name={props.task_added.appealType} />
                <CaseDetailsLink
                  appeal={props.task_added?.appealUuid ?
                    { externalId: props.task_added?.appealUuid } : { externalId: props.task_added?.externalId }}
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
                appeal?.id &&
                waiveEvidenceAlertBanner?.appealId.toString() === appeal?.id.toString() && (
                <Alert
                  type={waiveEvidenceAlertBanner.type}
                  message={waiveEvidenceAlertBanner.message}
                  scrollOnAlert={false}
                />
              )}
            </div>
          </div>
          <div className="tasks-added-details">
            {appeal ? renderTaskSectionByCount() :
              <span className="tasks-added-text-alternate">
                There are no tasks on this appeal. The linked appeal must be saved before tasks can be added.</span>}
          </div>
          {isAddTaskModalOpen &&
            <AddRelatedTaskModalCorrespondenceDetails
              title="Add Task"
              isOpen={isAddTaskModalOpen}
              handleClose={handleAddTaskModalClose}
              correspondence={props.correspondenceInfo}
              appeal={appeal}
              tasks={tasks}
              // autoTexts= {props.autoTexts}
            />
          }
        </div>
      )}
    </>
  );
};

CorrespondenceAppealTasks.propTypes = {
  correspondence: PropTypes.object,
  task_added: PropTypes.object,
  organizations: PropTypes.array,
  userCssId: PropTypes.string,
  appealUuid: PropTypes.string,
  waivableUser: PropTypes.bool,
  correspondenceInfo: PropTypes.object,
  setWaiveEvidenceAlertBanner: PropTypes.func,
  expandedLinkedAppeals: PropTypes.array
};

const mapStateToProps = (state) => ({
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo,
  waiveEvidenceAlertBanner: state.correspondenceDetails.waiveEvidenceAlertBanner,
  expandedLinkedAppeals: state.correspondenceDetails.expandedLinkedAppeals,
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    setWaiveEvidenceAlertBanner,
    updateExpandedLinkedAppeals
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CorrespondenceAppealTasks);
