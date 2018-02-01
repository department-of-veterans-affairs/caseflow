import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { onReceiveQueue } from './QueueActions';
import ApiUtil from '../util/ApiUtil';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import { associateTasksWithAppeals } from './utils';
import _ from 'lodash';

class QueueLoadingScreen extends React.PureComponent {
  createLoadPromise = () => {
    const userId = this.props.userId;
    const userQueueLoaded = !_.isEmpty(this.props.tasks) && !_.isEmpty(this.props.appeals) &&
      this.props.loadedUserId === userId;

    if (userQueueLoaded) {
      return Promise.resolve();
    }

    return ApiUtil.get(`/queue/tasks/${userId}`).then((response) => {
      const { appeals, tasks } = associateTasksWithAppeals(JSON.parse(response.text));

      this.props.onReceiveQueue({
        appeals,
        tasks,
        userId
      });
    });
  };

  reload = () => window.location.reload();

  render = () => {
    const failStatusMessageChildren = <div>
      It looks like Caseflow was unable to load your cases.<br />
      Please <a onClick={this.reload}>refresh the page</a> and try again.
    </div>;

    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading your appeals...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load appeals'
      }}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.props.children}
    </LoadingDataDisplay>;

    return <div className="usa-grid">
      {loadingDataDisplay}
    </div>;
  };
}

QueueLoadingScreen.propTypes = {
  userId: PropTypes.number.isRequired
};

const mapStateToProps = (state) => _.pick(state.queue.loadedQueue, 'tasks', 'appeals')

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveQueue
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(QueueLoadingScreen);
