import React from 'react';
import PropTypes from 'prop-types';
import { connect, useSelector } from 'react-redux';
import {
  appealWithDetailSelector,
  taskSnapshotTasksForAppeal,
  latestCaseTimelineTaskForAppeal } from './selectors';
import { css } from 'glamor';
import AddNewTaskButton from './components/AddNewTaskButton';
import TaskRows from './components/TaskRows';
import COPY from '../../COPY';
import { sectionSegmentStyling, sectionHeadingStyling, anchorJumpLinkStyling } from './StickyNavContentArea';
import { PulacCerulloReminderAlert } from './pulacCerullo/PulacCerulloReminderAlert';
import DocketSwitchAlertBanner from './docketSwitch/DocketSwitchAlertBanner';
import Alert from '../components/Alert';

const tableStyling = css({
  width: '100%',
  marginTop: '0px'
});

const alertStyling = css({
  borderBottom: 'none',
  marginBottom: 0
});

export const TaskSnapshot = ({ appeal, hideDropdown, tasks, latestCaseTimeLineTask, showPulacCerulloAlert }) => {
  const canEditNodDate = useSelector((state) => state.ui.canEditNodDate);
  const docketSwitchDisposition = appeal.docketSwitch?.disposition;
  const showBanner = (
  latestCaseTimeLineTask?.type === 'LegacyAppealAssignmentTrackingTask' &&
    (() => {
      const [{ locationUser }] = appeal?.locationHistory?.slice(-1) || [{}];
      const { css_id: locationUserCssId } = locationUser || {};

      return latestCaseTimeLineTask?.assignedTo.cssId === locationUserCssId;
    })()
  );
  const legacyTaskAlert = showBanner && <Alert
    type="info"
    message={COPY.TASK_SNAPSHOT_CASE_MOVED_ALERT_LABEL}
    lowerMargin
  />;

  const sectionBody = tasks.length ? (
    <>
      {legacyTaskAlert}
      <table {...tableStyling} summary="layout table">
        <tbody>
          <TaskRows
            appeal={appeal}
            taskList={tasks}
            timeline={false}
            editNodDateEnabled={!appeal.isLegacyAppeal && canEditNodDate}
            hideDropdown={hideDropdown}
          />
        </tbody>
      </table>
    </>
  ) : (
    COPY.TASK_SNAPSHOT_NO_ACTIVE_LABEL
  );

  return (
    <div className="usa-grid" id="currently-active-tasks" {...css({ marginTop: '3rem' })}>
      <h2 {...sectionHeadingStyling}>
        <a id="our-elemnt" {...anchorJumpLinkStyling}>
          {COPY.TASK_SNAPSHOT_ACTIVE_TASKS_LABEL}
        </a>
        <AddNewTaskButton appealId={appeal.externalId} />
      </h2>
      {showPulacCerulloAlert && (
        <div {...sectionSegmentStyling} {...alertStyling}>
          <PulacCerulloReminderAlert />
        </div>
      )}
      {docketSwitchDisposition === 'partially_granted' && (
        <div {...alertStyling} {...sectionSegmentStyling}>
          <DocketSwitchAlertBanner appeal={appeal} />
        </div>
      )}
      {appeal.switchedDockets?.some((docketSwitch) => docketSwitch.disposition !== 'denied') && (
        <div {...alertStyling} {...sectionSegmentStyling}>
          {appeal.switchedDockets?.map((docketSwitch) =>
            docketSwitch.disposition === 'denied' ? '' : (
              <DocketSwitchAlertBanner
                key={docketSwitch.id}
                appeal={appeal}
                docketSwitch={docketSwitch}
              />
            )
          )}
        </div>
      )}
      <div {...sectionSegmentStyling}>
        {sectionBody}
      </div>
    </div>
  );
};

TaskSnapshot.propTypes = {
  tasks: PropTypes.array,
  latestCaseTimeLineTask: PropTypes.object,
  appeal: PropTypes.object,
  hideDropdown: PropTypes.bool,
  showPulacCerulloAlert: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => {
  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    tasks: taskSnapshotTasksForAppeal(state, { appealId: ownProps.appealId }),
    latestCaseTimeLineTask: latestCaseTimelineTaskForAppeal(state, { appealId: ownProps.appealId }),
  };
};

export default connect(mapStateToProps)(TaskSnapshot);
