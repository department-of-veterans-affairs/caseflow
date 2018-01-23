import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { onReceiveQueue } from './QueueActions';
import ApiUtil from '../util/ApiUtil';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { COLORS } from './constants';
import { associateTasksWithAppeals } from './utils';

class QueueLoadingScreen extends React.PureComponent {
  createLoadPromise = () => {
    // todo: Promise.resolve() if appeals/tasks already loaded
    return ApiUtil.get(`/queue/${this.props.userId}`).then((response) => {
      const { appeals, tasks } = associateTasksWithAppeals(JSON.parse(response.text));

      this.props.onReceiveQueue({
        appeals,
        tasks
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
      loadingScreenProps={{
        spinnerColor: COLORS.QUEUE_LOGO_PRIMARY,
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

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveQueue
}, dispatch);

export default connect(null, mapDispatchToProps)(QueueLoadingScreen);
