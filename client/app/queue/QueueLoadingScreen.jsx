import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { onReceiveQueue, onReceiveJudges } from './QueueActions';
import ApiUtil from '../util/ApiUtil';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import { associateTasksWithAppeals } from './utils';
import _ from 'lodash';

class QueueLoadingScreen extends React.PureComponent {
  loadJudges = () => {
    if (!_.isEmpty(this.props.judges)) {
      return Promise.resolve();
    }

    return ApiUtil.get('/queue/judges').then((response) => {
      const judges = JSON.parse(response.text).judges;

      this.props.onReceiveJudges(_.keyBy(judges, 'css_id'));
    });
  }

  loadQueue = () => {
    const {
      userId,
      loadedUserId,
      tasks,
      appeals
    } = this.props;
    const userQueueLoaded = !_.isEmpty(tasks) && !_.isEmpty(appeals) && loadedUserId === userId;

    if (userQueueLoaded) {
      return Promise.resolve();
    }

    return ApiUtil.get(`/queue/${userId}`).then((response) => this.props.onReceiveQueue({
      ...associateTasksWithAppeals(JSON.parse(response.text)),
      userId
    }));
  };

  createLoadPromise = () => Promise.all([
    this.loadQueue(),
    this.loadJudges()
  ]);

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
        message: 'Loading your cases...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load your cases'
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

const mapStateToProps = (state) => ({
  ..._.pick(state.queue, 'judges'),
  ...state.queue.loadedQueue
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveQueue,
  onReceiveJudges
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(QueueLoadingScreen);
