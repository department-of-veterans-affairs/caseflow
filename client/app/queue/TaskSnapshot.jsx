import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';
import { appealWithDetailSelector, taskSnapshotTasksForAppeal } from './selectors';
import AddNewTaskButton from './components/AddNewTaskButton';
import TaskRows from './components/TaskRows';
import COPY from '../../COPY.json';
import { sectionSegmentStyling, sectionHeadingStyling, anchorJumpLinkStyling } from './StickyNavContentArea';
import { PulacCerulloReminderAlert } from '../pulacCerullo/PulacCerulloReminderAlert';

const tableStyling = css({
  width: '100%',
  marginTop: '0px'
});

const alertStyling = css({
  borderBottom: 'none',
  marginBottom: 0
});

export class TaskSnapshot extends React.PureComponent {
  render = () => {
    const { appeal, hideDropdown, tasks } = this.props;

    let sectionBody = COPY.TASK_SNAPSHOT_NO_ACTIVE_LABEL;

    if (tasks.length) {
      sectionBody = (
        <table {...tableStyling}>
          <tbody>{<TaskRows appeal={appeal} taskList={tasks} timeline={false} hideDropdown={hideDropdown} />}</tbody>
        </table>
      );
    }

    return (
      <div className="usa-grid" id="currently-active-tasks" {...css({ marginTop: '3rem' })}>
        <h2 {...sectionHeadingStyling}>
          <a id="our-elemnt" {...anchorJumpLinkStyling}>
            {COPY.TASK_SNAPSHOT_ACTIVE_TASKS_LABEL}
          </a>
          {<AddNewTaskButton appealId={appeal.externalId} />}
        </h2>
        <div {...sectionSegmentStyling} {...alertStyling}>
          <PulacCerulloReminderAlert />
        </div>
        <div {...sectionSegmentStyling}>{sectionBody}</div>
      </div>
    );
  };
}

const mapStateToProps = (state, ownProps) => {
  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    tasks: taskSnapshotTasksForAppeal(state, { appealId: ownProps.appealId })
  };
};

export default connect(mapStateToProps)(TaskSnapshot);
