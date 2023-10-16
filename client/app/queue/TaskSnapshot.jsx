import React from 'react';
import PropTypes from 'prop-types';
import { connect, useSelector } from 'react-redux';
import { appealWithDetailSelector, taskSnapshotTasksForAppeal } from './selectors';
import { css } from 'glamor';
import AddNewTaskButton from './components/AddNewTaskButton';
import TaskRows from './components/TaskRows';
import COPY from '../../COPY';
import { sectionSegmentStyling, sectionHeadingStyling, anchorJumpLinkStyling } from './StickyNavContentArea';
import { PulacCerulloReminderAlert } from './pulacCerullo/PulacCerulloReminderAlert';
import DocketSwitchAlertBanner from './docketSwitch/DocketSwitchAlertBanner';

const tableStyling = css({
  width: '100%',
  marginTop: '0px'
});

const alertStyling = css({
  borderBottom: 'none',
  marginBottom: 0
});

export const TaskSnapshot = ({ appeal, hideDropdown, tasks, showPulacCerulloAlert }) => {
  const canEditNodDate = useSelector((state) => state.ui.canEditNodDate);
  const docketSwitchDisposition = appeal.docketSwitch?.disposition;

  const sectionBody = tasks.length ? (
    <table {...tableStyling} summary="layout table">
      <tbody>
        <TaskRows appeal={appeal}
          taskList={tasks}
          timeline={false}
          editNodDateEnabled={!appeal.isLegacyAppeal && canEditNodDate}
          hideDropdown={hideDropdown}
        />
      </tbody>
    </table>
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
      <div {...alertStyling} {...sectionSegmentStyling}>
        { docketSwitchDisposition === 'partially_granted' &&
          <DocketSwitchAlertBanner appeal={appeal} />
        }
      </div>
      <div {...alertStyling} {...sectionSegmentStyling}>
        { appeal.switchedDockets ? appeal.switchedDockets.map((docketSwitch) =>
          docketSwitch.disposition === 'denied' ? '' :
            <DocketSwitchAlertBanner appeal={appeal} docketSwitch={docketSwitch} />) :
          ''
        }
      </div>
      <div {...sectionSegmentStyling}>{sectionBody}</div>
    </div>
  );
};

TaskSnapshot.propTypes = {
  tasks: PropTypes.array,
  appeal: PropTypes.object,
  hideDropdown: PropTypes.bool,
  showPulacCerulloAlert: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => {
  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    tasks: taskSnapshotTasksForAppeal(state, { appealId: ownProps.appealId })
  };
};

export default connect(mapStateToProps)(TaskSnapshot);
