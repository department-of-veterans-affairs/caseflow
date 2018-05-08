import _ from 'lodash';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';
import { associateTasksWithAppeals } from './utils';

import { setActiveAppeal } from './CaseDetail/CaseDetailActions';
import { onReceiveQueue, onReceiveJudges } from './QueueActions';

class QueueLoadingScreen extends React.PureComponent {
  loadJudges = () => {
    if (!_.isEmpty(this.props.judges)) {
      return Promise.resolve();
    }

    return ApiUtil.get('/users?role=Judge').then((response) => {
      const resp = JSON.parse(response.text);
      const judges = _.keyBy(resp.judges, 'id');

      this.props.onReceiveJudges(judges);
    });
  }

  loadRelevantCases = () => {
    if (this.props.vacolsId) {
      return this.loadActiveAppeal();
    }

    return this.loadQueue();
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

  loadActiveAppeal = () => {
    if (this.props.activeAppeal) {
      return Promise.resolve();
    }

    return ApiUtil.get(`/appeals/${this.props.vacolsId}`).then((response) => {
      const resp = JSON.parse(response.text);

      this.props.setActiveAppeal(resp.appeal);
    });
  };

  createLoadPromise = () => Promise.all([
    this.loadRelevantCases(),
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
  ...state.caseDetail.activeAppeal,
  ...state.queue.loadedQueue
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveQueue,
  onReceiveJudges,
  setActiveAppeal
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(QueueLoadingScreen);
