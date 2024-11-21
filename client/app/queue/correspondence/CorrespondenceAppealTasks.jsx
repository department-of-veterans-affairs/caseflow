import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import CaseDetailsLink from '../CaseDetailsLink';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import { appealWithDetailSelector, taskSnapshotTasksForAppeal } from '../selectors';
import { useSelector, useDispatch, connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import TaskRows from '../components/TaskRows';
import Alert from '../../components/Alert';
import Button from '../../components/Button';
import {
  updateExpandedLinkedAppeals
} from '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';
import AddRelatedTaskModalCorrespondenceDetails from
  './intake/components/TasksAppeals/AddRelatedTaskModalCorrespondenceDetails';
import { renderLegacyAppealType, statusLabel } from 'app/queue/utils';

const CorrespondenceAppealTasks = (props) => {
  const {
    waiveEvidenceAlertBanner,
    taskRelatedToAppealBanner,
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

  useEffect(() => {
    if (
      taskRelatedToAppealBanner?.message &&
      taskRelatedToAppealBanner?.appealId?.toString() === appeal?.id?.toString()
    ) {

      dispatch(updateExpandedLinkedAppeals(expandedLinkedAppeals, appealId));

    }
  }, [taskRelatedToAppealBanner, appeal]);

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
        classNames={['usa-button-secondary tasks-added-button-spacing']}
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
          <h2>Linked Appeal:</h2>
          <div className="case-details-header-badge">
            <DocketTypeBadge name={props.appeal.appealType} />
            <CaseDetailsLink
              appeal={props.appeal?.appealUuid ?
                { externalId: props.appeal?.appealUuid } : { externalId: props.appeal?.externalId }}
              getLinkText={() => props.appeal.docketNumber}
              task={props.appeal}
              linkOpensInNewTab
            />
          </div>
          <div className="number-of-issues-header">
            Number of issues:
            <span>{props.appeal.numberOfIssues}</span>
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
              <p className="task-added-header">DOCKET</p>
              <div className="task-added-value">
                <span className="case-details-badge">
                  <DocketTypeBadge name={props.appeal.appealType} />
                  <CaseDetailsLink
                    appeal={props.appeal?.appealUuid ?
                      { externalId: props.appeal?.appealUuid } : { externalId: props.appeal?.externalId }}
                    getLinkText={() => props.appeal.docketNumber}
                    task={props.appeal}

                    linkOpensInNewTab
                  />
                </span>
              </div>
            </div>
            <div className="corr-tasks-added-col">
              <p className="task-added-header">APPELLANT NAME</p>
              <p className="task-added-value">{veteranFullName}</p>
            </div>
            <div className="corr-tasks-added-col">
              <p className="task-added-header">APPEAL STREAM TYPE</p>
              <p className="stream-type task-added-value">{renderLegacyAppealType({
                aod: props.appeal.aod,
                type: props.appeal.caseType
              })}</p>
            </div>
            <div className="corr-tasks-added-col">
              <p className="task-added-header">NUMBER OF ISSUES</p>
              <p className="task-added-value">{props.appeal.numberOfIssues}</p>
            </div>
            <div className="corr-tasks-added-col">
              <p className="task-added-header">STATUS</p>
              <p className="task-added-value">
                {props.appeal.withdrawn === true ? 'Withdrawn' : statusLabel(props.appeal)}
              </p>
            </div>
            <div className="corr-tasks-added-col">
              <p className="task-added-header">ASSIGNED TO</p>
              <p className="task-added-value">{props.appeal.assignedTo ? props.appeal.assignedTo.name : ''}</p>
            </div>
          </div>
          <div className="tasks-added-banner-alert">
            <div className="task-banner-alert">
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
          <div className="tasks-added-banner-alert">
            <div className="task-banner-alert">
              {appeal &&
                taskRelatedToAppealBanner &&
                taskRelatedToAppealBanner?.message &&
                taskRelatedToAppealBanner?.appealId &&
                appeal?.id &&
                taskRelatedToAppealBanner?.appealId.toString() === appeal?.id.toString() && (
                <Alert
                  type={taskRelatedToAppealBanner.type}
                  message={taskRelatedToAppealBanner.message}
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
              autoTexts= {props.autoTexts}
            />
          }
        </div>
      )}
    </>
  );
};

CorrespondenceAppealTasks.propTypes = {
  correspondence: PropTypes.object,
  appeal: PropTypes.object,
  organizations: PropTypes.array,
  userCssId: PropTypes.string,
  appealUuid: PropTypes.string,
  waivableUser: PropTypes.bool,
  correspondenceInfo: PropTypes.object,
  expandedLinkedAppeals: PropTypes.array
};

const mapStateToProps = (state) => ({
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo,
  waiveEvidenceAlertBanner: state.correspondenceDetails.waiveEvidenceAlertBanner,
  taskRelatedToAppealBanner: state.correspondenceDetails.taskRelatedToAppealBanner,
  expandedLinkedAppeals: state.correspondenceDetails.expandedLinkedAppeals,
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    updateExpandedLinkedAppeals
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CorrespondenceAppealTasks);
