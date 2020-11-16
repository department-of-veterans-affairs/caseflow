import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { caseTimelineTasksForAppeal } from './selectors';
import COPY from '../../COPY';
import TaskRows from './components/TaskRows';
import Alert from 'app/components/Alert';

export class CaseTimeline extends React.PureComponent {
  constructor() {
    super();
    this.state = { editNODChangeSuccessful: false };
  }

  handleEditNODChange = (editNODChangeSuccessful) => {
    this.setState({ editNODChangeSuccessful });
    setInterval(() => {
      this.setState((state) => ({
        editNODChangeSuccessful: !state.editNODChangeSuccessful
      }));
    }, 5000);
  }

  render = () => {
    const {
      appeal,
      tasks,
    } = this.props;

    return <React.Fragment>
      {COPY.CASE_TIMELINE_HEADER}
      {this.state.editNODChangeSuccessful &&
        <Alert
          type="success"
          title={COPY.EDIT_NOD_SUCCESS_ALERT_TITLE}
          message={COPY.EDIT_NOD_SUCCESS_ALERT_MESSAGE}
        />
      }
      <table id="case-timeline-table" summary="layout table">
        <tbody>
          <TaskRows appeal={appeal}
            taskList={tasks}
            onEditNODChange={this.handleEditNODChange}
            editNodDateEnabled={this.props.featureToggles?.editNodDate}
            timeline
          />
        </tbody>
      </table>
    </React.Fragment>;
  }
}

CaseTimeline.propTypes = {
  appeal: PropTypes.object,
  tasks: PropTypes.array,
  featureToggles: PropTypes.object
};

const mapStateToProps = (state, ownProps) => {
  return {
    tasks: caseTimelineTasksForAppeal(state, { appealId: ownProps.appeal.externalId }),
    featureToggles: state.ui.featureToggles
  };
};

export default connect(mapStateToProps)(CaseTimeline);
