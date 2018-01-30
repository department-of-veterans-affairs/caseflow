import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { onReceiveQueue } from './QueueActions';
import ApiUtil from '../util/ApiUtil';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { COLORS } from './constants';
import { associateTasksWithAppeals } from './utils';
import _ from 'lodash';

class QueueLoadingScreen extends React.PureComponent {
  createLoadPromise = () => {
    // todo: Promise.resolve() if appeals/tasks already loaded
    return ApiUtil.get(`/queue/${this.props.userId}`).then((response) => {
      const { appeals, tasks } = associateTasksWithAppeals(JSON.parse(response.text));

      const tasksById = _.keyBy(tasks, 'id');
      const appealsById = _(appeals).
        map((appeal) => _.extend(appeal, { docCount: 0 })).
        keyBy('id').
        value();

      this.props.onReceiveQueue({
        appeals: appealsById,
        tasks: tasksById
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
