import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { onReceiveQueue } from './QueueActions';
import ApiUtil from '../util/ApiUtil';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import * as Constants from './constants';

class QueueLoadingScreen extends React.PureComponent {
  getUserId = () => 1;

  createLoadPromise = () => {
    // todo: Promise.resolve() if appeals/tasks already loaded
    // todo: return ApiUtil.get(`/queue/${this.props.userId}`, {}).
    return ApiUtil.get(`/queue/${this.getUserId()}`, {}).then((response) => {
      const {
        appeals: { data: appeals },
        tasks: { data: tasks }
      } = JSON.parse(response.text);

      // todo: Attorneys currently only have one task per appeal, but future users might have multiple
      _.each(appeals, (appeal) => {
        appeal.tasks = tasks.filter((task) => task.attributes.appeal_id === appeal.attributes.vacols_id);
      });

      this.props.onReceiveQueue({
        appeals,
        tasks
      });
    });
  };

  reload = () => window.location.reload();

  render = () => {
    const failStatusMessageChildren = <div>
      It looks like Caseflow was unable to load this case.<br/>
      Please <a onClick={this.reload}>refresh the page</a> and try again.
    </div>;

    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingScreenProps={{
        spinnerColor: Constants.QUEUE_COLOR,
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

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveQueue
}, dispatch);

export default connect(null, mapDispatchToProps)(QueueLoadingScreen);
