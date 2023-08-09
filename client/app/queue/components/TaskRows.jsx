/* eslint-disable max-lines */
import { css } from 'glamor';
import React from 'react';
import moment from 'moment';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import COPY from '../../../COPY';
import { CancelIcon } from '../../components/icons/CancelIcon';
import { GrayDotIcon } from '../../components/icons/GrayDotIcon';
import { GreenCheckmarkIcon } from '../../components/icons/GreenCheckmarkIcon';
import { COLORS } from '../../constants/AppConstants';
import { taskIsOnHold, sortCaseTimelineEvents, timelineEventsFromAppeal } from '../utils';
import CaseDetailsDescriptionList from '../components/CaseDetailsDescriptionList';
import ActionsDropdown from '../components/ActionsDropdown';
import OnHoldLabel from '../components/OnHoldLabel';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import DecisionDateTimeLine from '../components/DecisionDateTimeLine';
import ReactMarkdown from 'react-markdown';
import { EditNodDateModalContainer } from './EditNodDateModal';
import { NodDateUpdateTimeline } from './NodDateUpdateTimeline';
import { SubstituteAppellantTimelineEvent } from '../substituteAppellant/timelineEvent/SubstituteAppellantTimelineEvent'; // eslint-disable-line max-len
import { SubstitutionProcessedTimelineEvent } from '../substituteAppellant/timelineEvent/SubstitutionProcessedTimelineEvent'; // eslint-disable-line max-len

export const grayLineStyling = css({
  width: '5px',
  background: COLORS.GREY_LIGHT,
  margin: 'auto',
  position: 'absolute',
  top: '30px',
  left: '45.5%',
  bottom: 0
});

export const grayLineTimelineStyling = css(grayLineStyling, { left: '9%',
  marginLeft: '12px',
  top: '39px' });

const greyDotAndlineStyling = css({ top: '25px' });

const closedAtIcon = (task, timeline) => {
  return (task.closedAt && timeline ? <GreenCheckmarkIcon /> : <GrayDotIcon size={25} />);
};

const taskContainerStyling = css({
  border: 'none',
  verticalAlign: 'top',
  padding: '3px',
  paddingBottom: '3rem'
});

const taskInfoWithIconContainer = css({
  textAlign: 'center',
  border: 'none',
  padding: '0 0 0 0',
  position: 'relative',
  verticalAlign: 'top',
  width: '15px'
});

const taskTimeContainerStyling = css(taskContainerStyling, { width: '20%' });
const taskInformationContainerStyling = css(taskContainerStyling, { width: '25%' });
const taskTimeTimelineContainerStyling = css(taskContainerStyling, { width: '40%' });
const taskInfoWithIconTimelineContainer =
  css(taskInfoWithIconContainer, { textAlign: 'left',
    marginLeft: '5px',
    width: '10%',
    paddingLeft: '0px' });

const isCancelled = (task) => {
  return task.status === TASK_STATUSES.cancelled;
};

const issueUpdateTask = (task) =>{
  return task.type === 'IssuesUpdateTask';
}

const establishmentTask = (task) => {
  return task.type === 'EstablishmentTask';
}

const tdClassNames = (timeline, task) => {
  const containerClass = timeline ? taskInfoWithIconTimelineContainer : '';
  const closedAtClass = task.closedAt ? null : <span className="greyDotTimelineStyling"></span>;

  return [containerClass, closedAtClass].filter((val) => val).join(' ');
};

const cancelGrayTimeLineStyle = (timeline) => {
  return timeline ? grayLineTimelineStyling : '';
};

class TaskRows extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      taskInstructionsIsVisible: {},
      showEditNodDateModal: false,
      activeTasks: [...props.taskList],
    };
  }

  toggleTaskInstructionsVisibility = (task) => {
    const previousState = Object.assign(
      {},
      this.state.taskInstructionsIsVisible
    );

    previousState[task.uniqueId] = previousState[task.uniqueId] ?
      !previousState[task.uniqueId] :
      true;
    this.setState({ taskInstructionsIsVisible: previousState });
  };

  daysSinceTaskAssignmentListItem = (task) => {
    if (task) {
      const today = moment().startOf('day');
      const dateAssigned = moment(task.assignedOn);
      const dayCountSinceAssignment = today.diff(dateAssigned, 'days');

      return (
        <React.Fragment>
          <dt>{COPY.TASK_SNAPSHOT_DAYS_SINCE_ASSIGNMENT_LABEL}</dt>
          <dd>{dayCountSinceAssignment}</dd>
        </React.Fragment>
      );
    }

    return null;
  };

  assignedOnListItem = (task) => {
    if (task.closedAt) {
      return null;
    }

    return task.assignedOn ? (
      <div className="cf-row-wrapper">
        <dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL}</dt>
        <dd>{moment(task.assignedOn).format('MM/DD/YYYY')}</dd>
      </div>
    ) : null;
  };

  closedAtListItem = (task) => {
    return task.closedAt ? (
      <div className="cf-row-wrapper">
        <dt>{COPY.TASK_SNAPSHOT_TASK_COMPLETED_DATE_LABEL}</dt>
        <dd>{moment(task.closedAt).format('MM/DD/YYYY')}</dd>
      </div>
    ) : null;
  };

  cancelledAtListItem = (task) => {
    return (
      <div className="cf-row-wrapper">
        <dt>{COPY.TASK_SNAPSHOT_TASK_CANCELLED_DATE_LABEL}</dt>
        <dd>{moment(task.closedAt).format('MM/DD/YYYY')}</dd>
      </div>
    );
  };

  daysWaitingListItem = (task) => {
    if (task.closedAt) {
      return null;
    }

    return taskIsOnHold(task) ? (
      <div className="cf-row-wrapper">
        <dt>{COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE}</dt>
        <dd>
          <OnHoldLabel task={task} />
        </dd>
      </div>
    ) : (
      this.daysSinceTaskAssignmentListItem(task)
    );
  };

  assignedToListItem = (task) => {
    const assignee = task.assigneeName;

    return assignee && !establishmentTask(task) ? (
      <div className="cf-row-wrapper">
        <dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt>
        <dd>{assignee}</dd>
      </div>
    ) : null;
  };

  getAbbrevName = ({ firstName, lastName }) =>
    `${firstName.substring(0, 1)}. ${lastName}`;

  assignedByListItem = (task) => {
    const assignor = task.assignedBy.firstName ?
      this.getAbbrevName(task.assignedBy) :
      null;

    return assignor ? (
      <div className="cf-row-wrapper">
        <dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNOR_LABEL}</dt>
        <dd>{assignor}</dd>
      </div>
    ) : null;
  };

  cancelledByListItem = (task) => {
    const canceler = task.cancelledBy?.cssId;

    return canceler ? (
      <div className="cf-row-wrapper">
        <dt>{COPY.TASK_SNAPSHOT_TASK_CANCELER_LABEL}</dt>
        <dd>{canceler}</dd>
      </div>
    ) : null;
  };

  cancelReasonListItem = (task) => {
    const reason = task.cancelReason;
    const reasonLabel = COPY.TASK_SNAPSHOT_CANCEL_REASONS[reason];

    return reasonLabel ? <div className="cf-row-wrapper"><dt>{COPY.TASK_SNAPSHOT_TASK_CANCEL_REASON_LABEL}</dt>
      <dd>{reasonLabel}</dd></div> : null;
  }

  completedByListItem = (task) => {
    const completedBy = task?.completedBy?.cssId;

    return completedBy ? (
      <div className="cf-row-wrapper">
        <dt>{COPY.TASK_SNAPSHOT_TASK_COMPLETED_BY_LABEL}</dt>
        <dd>{completedBy}</dd>
      </div>
    ) : null;
  };

  splitAtListItem = (task) => {
    return (
      <div className="cf-row-wrapper">
        <dt>{[COPY.TASK_SNAPSHOT_TASK_COMPLETED_DATE_LABEL, <br />, moment(task.closedAt).format('MM/DD/YYYY')]}</dt>
      </div>
    );
  };

  splitByListItem = (task) => {
    const spliter = task.cancelledBy?.cssId;

    if (spliter) {
      return (
        <div className="cf-row-wrapper">
          <dt>{COPY.TASK_SPLIT_BY}</dt>
          <dd>{spliter}</dd>
        </div>
      );
    }

    return null;
  };

  splitInstruction = () => {
    return <div className="cf-row-wrapper"><dt>{COPY.TASK_SPLIT_INSTRUCTION}</dt></div>;
  }

  splitReasonListItem = (task) => {
    const reason = task.cancelReason;

    return reason ? <div className="cf-row-wrapper"><dt>{COPY.TASK_SPLIT_REASON}</dt>
      <dd>{reason}</dd></div> : null;
  }

  hearingRequestTypeConvertedBy = (task) => {
    const convertedBy = task.convertedBy?.cssId;

    return convertedBy ? (
      <div className="cf-row-wrapper">
        <dt>{COPY.TASK_SNAPSHOT_HEARING_REQUEST_CONVERTER_LABEL}</dt>
        <dd>{convertedBy}</dd>
      </div>
    ) : null;
  };

  taskLabelListItem = (task) => {
    if (task.closedAt) {
      return null;
    }

    return task.label ? (
      <div className="cf-row-wrapper">
        <dt>{COPY.TASK_SNAPSHOT_TASK_TYPE_LABEL}</dt>
        <dd>{task.label}</dd>
      </div>
    ) : null;
  };

  taskInstructionsWithLineBreaks = (task) => {
    if (!task.instructions || !task.instructions.length) {
      return <br />;
    }

    // We aren't allowing ReactMarkdown to do full HTML parsing, so we'll convert any `<br>`
    // or newline characters to the Markdown standard of two spaces followed by \n
    const formatBreaks = (text = '') => {
      // Somehow the contents are occasionally an array, at least in tests
      // Here we'll format the individual items, then just join to ensure we return string
      if (Array.isArray(text)) {
        return text.
          map((item) => item.replace(/<br>|(?<! {2})\n/g, '  \n')).
          join(' ');
      }

      // Normally this should just be a string
      return text.replace(/<br>|(?<! {2})\n/g, '  \n');
    };

    const renderMstLabel = (mstText, style) => {
      if (mstText) {
        return <React.Fragment>
          <h5 style={style}>Reason for Change (MST):</h5>
          <small>{mstText}</small>
        </React.Fragment>;
      }
    };

    const renderPactLabel = (pactText, style) => {
      if (pactText) {
        return <React.Fragment>
          <h5 style={style}>Reason for Change (PACT):</h5>
          <small>{pactText}</small>
        </React.Fragment>;
      }
    };

    // formatting used for IssueUpdate task instructions.
    const formatIssueUpdateBreaks = (text = '') => {
      const divStyle = { marginTop: '1rem' };
      const hStyle = { marginTop: '1.5rem', marginBottom: '0rem', fontWeight: 'bold' };

      if (Array.isArray(text)) {
        // text array indexes
        // 0: change_type,
        // 1: benefit_type,
        // 2: issue description,
        // 3: original special issues list
        // 4: updated special issues list
        // 5: mst edit reason (not currently implemented)
        // 6: pact edit reason (not currently implemented)
        return (
          <div style={divStyle}>
            <b>{text[0]}:</b>
            {text[1] &&
              <React.Fragment>
                <div style={divStyle}>
                  Benefit type: {text[1]}
                </div>
              </React.Fragment>}
            <div style={divStyle}>
              <div style={{whiteSpace: 'pre-line'}}>
                {text[2]}
              </div>
            </div>
            {text[4] ?
              <React.Fragment>
              <h5 style={hStyle}>Original:</h5>
              <div style={divStyle}>
                <small>{text[3]}</small>
              </div>
                <h5 style={hStyle}>Updated:</h5>
                <div style={divStyle}>
                  <small>{text[4]}</small>
              </div>
              </React.Fragment> :
                <div style={divStyle}>
                  {text[3]}
                </div>}
            {renderMstLabel(text[5], hStyle)}
            {renderPactLabel(text[6], hStyle)}
          </div>
        );
      }
    };

    const formatEstablishmentBreaks = (text = '') => {
      const divStyle = { marginTop: '1rem'};
      const hStyle = { marginTop: '1rem', marginBottom: '0rem', fontWeight: 'bold' };
      if (Array.isArray(text)) {
        const content = text.map((issue, index) =>
        // issue array indexes:
        // 0: Issue description
        // 1: Benefit Type
        // 2: Original special issues (empty string unless issue originated in VBMS AND mst/pact designation changes by intake user)
        // 3: Special issues (Either added by intake user or originating in VBMS - if left unaltered during intake)
          <div key={index}>
            <div style={divStyle}>
              <b>Added Issue:</b>
            </div>
            <div style={divStyle}>
              {issue[0]}
            </div>
            {issue.at(1) != "" &&
              <React.Fragment>
                <div style={divStyle}>
                  Benefit type: {issue[1]}
                </div>
              </React.Fragment>}
            {/* Condition where a prior decision from vbms with mst/pact designation was updated in intake process */}
            {issue[2] ?
              <React.Fragment>
                <h5 style={hStyle}>ORIGINAL: </h5>
                <small>{issue[2]}</small>
                <h5 style={hStyle}>UPDATED: </h5>
                <small>{issue[3]}</small>
                <p></p>
              </React.Fragment> :
              <div style={divStyle}>
                {issue[3]}
                <p></p>
              </div>
            }
            {/* No horizontal rule after the last issue */}
            {index !== (text.length - 1) &&
              <React.Fragment>
                <div style={divStyle}>
                  <hr />
                </div>
              </React.Fragment>
            }
          </div>
        );

        return (
          <div>
            {content}
          </div>
        );
      }
    };

    // We specify the same 2.4rem margin-bottom as paragraphs to each set of instructions
    // to ensure a consistent margin between instruction content and the "Hide" button
    const divStyles = { marginBottom: '2.4rem' };

    const formatInstructions = (task, text) => {
      if (issueUpdateTask(task)) {
        return (
          <React.Fragment>{formatIssueUpdateBreaks(text)}</React.Fragment>
        );
      } else if (establishmentTask(task)) {
        return (
          <React.Fragment>{formatEstablishmentBreaks(text)}</React.Fragment>
        );
      } else {
        return (
          <ReactMarkdown>{formatBreaks(text)}</ReactMarkdown>
        );
      }
    };

    return (
      <React.Fragment key={`${task.uniqueId} fragment`}>
        {task.instructions.map((text) => (
          <React.Fragment key={`${task.uniqueId} div`}>
            <div
              key={`${task.uniqueId} instructions`}
              style={divStyles}
              className="task-instructions"
            >
              {
                formatInstructions(task, text)
              }
            </div>
          </React.Fragment>
        ))}
      </React.Fragment>
    );
  };

  taskInstructionsListItem = (task) => {
    if (!task.instructions || !task.instructions.length > 0) {
      return null;
    }

    return (
      <div className="cf-row-wrapper">
        {this.state.taskInstructionsIsVisible[task.uniqueId] && (
          <React.Fragment key={`${task.uniqueId}instructions_text`}>
            {!establishmentTask(task) &&
            <dt style={{ width: '100%' }}>
              {COPY.TASK_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}
            </dt>
            }
            <dd style={{ width: '100%' }}>
              {this.taskInstructionsWithLineBreaks(task)}
            </dd>
          </React.Fragment>
        )}
        <Button
          linkStyling
          styling={css({ padding: '0' })}
          id={task.uniqueId}
          name={
            this.state.taskInstructionsIsVisible[task.uniqueId] ?
              COPY.TASK_SNAPSHOT_HIDE_TASK_INSTRUCTIONS_LABEL :
              COPY.TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL
          }
          onClick={() => this.toggleTaskInstructionsVisibility(task)}
        />
      </div>
    );
  };

  showActionsListItem = (task, appeal) => {
    if (task.availableActions.length <= 0) {
      return null;
    }

    return this.showActionsSection(task) ? (
      <div>
        <h3>{COPY.TASK_SNAPSHOT_ACTION_BOX_TITLE}</h3>
        <ActionsDropdown task={task} appealId={appeal.externalId} />
      </div>
    ) : null;
  };

  showActionsSection = (task) => task && !this.props.hideDropdown;

  hearingRequestTypeConvertedAtListItem = (task) => {
    return task.convertedOn ? (
      <div className="cf-row-wrapper">
        <dt>{COPY.TASK_SNAPSHOT_HEARING_REQUEST_CONVERTED_ON_LABEL}</dt>
        <dd>{moment(task.convertedOn).format('MM/DD/YYYY')}</dd>
      </div>
    ) : null;
  };

  closedOrCancelledAtListItem = (task) => {
    if (isCancelled(task)) {
      return this.cancelledAtListItem(task);
    }

    return task.type === 'ChangeHearingRequestTypeTask' ?
      this.hearingRequestTypeConvertedAtListItem(task) :
      this.closedAtListItem(task);
  };

  showTimelineDescriptionSplitItems = (task) => {
    return (
      <React.Fragment>
        {this.splitByListItem(task)}
        {this.splitInstruction(task)}
        {this.splitReasonListItem(task)}
      </React.Fragment>
    );
  };

  showTimelineDescriptionItems = (task, timeline) => {
    if (task.type === 'ChangeHearingRequestTypeTask' && timeline) {
      return this.hearingRequestTypeConvertedBy(task);
    }

    return (
      <React.Fragment>
        {task.type !== 'IssuesUpdateTask' && this.assignedToListItem(task)}
        {this.assignedByListItem(task)}
        {this.cancelledByListItem(task)}
        {this.cancelReasonListItem(task)}
        {this.completedByListItem(task)}
        {this.taskLabelListItem(task)}
        {this.taskInstructionsListItem(task)}
      </React.Fragment>
    );
  };

  taskTemplate = (templateConfig) => {
    const {
      task,
      sortedTimelineEvents,
      index,
      timeline,
      appeal,
    } = templateConfig;

    const timelineTitle = isCancelled(task) ?
      `${task.type} cancelled` :
      task.timelineTitle;

    return (
      <tr key={task.uniqueId}>
        <td
          {...taskTimeContainerStyling}
          className={timeline ? taskTimeTimelineContainerStyling : ''}
        >
          <CaseDetailsDescriptionList>
            {this.assignedOnListItem(task)}
            {this.closedOrCancelledAtListItem(task)}
            {!task.closedAt && this.daysWaitingListItem(task)}
          </CaseDetailsDescriptionList>

        </td>
        <td
          {...taskInfoWithIconContainer}
          className={tdClassNames(timeline, task)}
        >
          {isCancelled(task) ? <CancelIcon /> : closedAtIcon(task, timeline)}

          {((index < sortedTimelineEvents.length && timeline) ||
            (index < this.state.activeTasks.length - 1 && !timeline)) && (
            <div
              {...grayLineStyling}
              className={[
                cancelGrayTimeLineStyle(timeline),
                task.closedAt ? '' : greyDotAndlineStyling,
              ].join(' ')}
            />
          )}
        </td>
        <td
          {...taskInformationContainerStyling}
          className={timeline ? 'taskInformationTimelineContainerStyling' : ''}
        >
          <CaseDetailsDescriptionList>
            {timeline && timelineTitle}
            {this.showTimelineDescriptionItems(task, timeline)}
          </CaseDetailsDescriptionList>

        </td>
        {!timeline && (
          <td className="taskContainerStyling taskActionsContainerStyling">
            {this.showActionsListItem(task, appeal)}{' '}
          </td>
        )}
      </tr>
    );
  };

  toggleEditNodDateModal = () =>
    this.setState((state) => ({
      showEditNodDateModal: !state.showEditNodDateModal,
    }));

  handleNODDateChange = () => {
    this.toggleEditNodDateModal();
  };

  // Certain events are only relevant to full timeline view
  timelineOnly = (eventType) =>
    [
      'decisionDate',
      'substitutionDate',
      'substitutionProcessed',
      'nodDateUpdate',
    ].includes(eventType);

  timelineComponent = (componentProps) => {
    const componentMap = {
      decisionDate: DecisionDateTimeLine,
      nodDateUpdate: NodDateUpdateTimeline,
      substitutionDate: SubstituteAppellantTimelineEvent,
      substitutionProcessed: SubstitutionProcessedTimelineEvent
    };
    const ComponentName = componentMap[componentProps.timelineEvent?.type];

    return ComponentName ? <ComponentName {...componentProps} /> : null;
  };

  render = () => {
    const { appeal, taskList, timeline } = this.props;
    // Non-tasks are only relevant for the main Case Timeline
    const eventsFromAppeal = timeline ?
      timelineEventsFromAppeal({ appeal }) :
      [];
    const sortedTimelineEvents = sortCaseTimelineEvents(
      taskList,
      eventsFromAppeal
    );

    return (
      <React.Fragment key={appeal.externalId}>
        {sortedTimelineEvents.map((timelineEvent, index) => {
          if (timeline && this.timelineOnly(timelineEvent.type)) {
            return this.timelineComponent({
              timelineEvent,
              appeal,
              timeline,
              taskList,
              index,
            });
          }

          const templateConfig = {
            task: timelineEvent,
            index,
            timeline,
            sortedTimelineEvents,
            appeal,
          };

          return this.taskTemplate(templateConfig);
        })}

        {/* Tasks and decision dates won't be in chronological order unless added to task list
          to return under render function*/}
        {timeline && appeal.isLegacyAppeal && (
          <tr>
            <td className="taskContainerStyling taskTimeTimelineContainerStyling">
              {appeal.form9Date ?
                moment(appeal.form9Date).format('MM/DD/YYYY') :
                null}
            </td>
            <td
              {...taskInfoWithIconTimelineContainer}
              className={appeal.form9Date ? '' : 'greyDotStyling'}
            >
              {appeal.form9Date ? <GreenCheckmarkIcon /> : <GrayDotIcon size={25} />}
              {appeal.nodDate && (
                <div className="grayLineStyling grayLineTimelineStyling" />
              )}
            </td>
            <td className="taskContainerStyling taskInformationTimelineContainerStyling">
              {appeal.form9Date ?
                COPY.CASE_TIMELINE_FORM_9_RECEIVED :
                COPY.CASE_TIMELINE_FORM_9_PENDING}
            </td>
          </tr>
        )}
        {timeline && appeal.nodDate && (
          <tr>
            <td className="taskContainerStyling taskTimeTimelineContainerStyling">
              {moment(appeal.nodDate).format('MM/DD/YYYY')}
            </td>
            <td className="taskInfoWithIconContainer taskInfoWithIconTimelineContainer">
              <GreenCheckmarkIcon />
            </td>
            <td className="taskContainerStyling taskInformationTimelineContainerStyling">
              {COPY.CASE_TIMELINE_NOD_RECEIVED} <br />
              {this.props.editNodDateEnabled && (
                <React.Fragment>
                  <p>
                    <Button
                      type="button"
                      linkStyling
                      styling={css({ paddingLeft: '0' })}
                      onClick={this.toggleEditNodDateModal}
                    >
                      {COPY.CASE_DETAILS_EDIT_NOD_DATE_LINK_COPY}
                    </Button>
                  </p>
                  {this.state.showEditNodDateModal && (
                    <EditNodDateModalContainer
                      onCancel={this.toggleEditNodDateModal}
                      onSubmit={this.toggleEditNodDateModal}
                      nodDate={appeal.nodDate}
                      appealId={appeal.externalId}
                    />
                  )}
                </React.Fragment>
              )}
            </td>
          </tr>
        )}
      </React.Fragment>
    );
  };
}

TaskRows.propTypes = {
  appeal: PropTypes.object,
  editNodDateEnabled: PropTypes.bool,
  hideDropdown: PropTypes.bool,
  taskList: PropTypes.array,
  timeline: PropTypes.bool,
};

export default TaskRows;
/* eslint-enable max-lines */
