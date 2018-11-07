// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';
import { extractAppealsAndAmaTasks } from './utils';

import {
  onReceiveQueue
} from './QueueActions';

import {
  setActiveOrganizationId
} from './uiReducer/uiActions';

type Params = {|
  children: React.Node,
  urlToLoad: string
|};

type Props = Params & {|
  // Action creators
  onReceiveQueue: typeof onReceiveQueue,
  setActiveOrganizationId: typeof setActiveOrganizationId
|};

class OrganizationQueueLoadingScreen extends React.PureComponent<Props> {
  // TODO: Short-circuit this request if we already have the tasks for this organization's queue.
  createLoadPromise = () => ApiUtil.get(this.props.urlToLoad, { timeout: { response: 5 * 60 * 1000 } }).then(
    (response) => {
      const {
        tasks: { data: tasks },
        id
      } = JSON.parse(response.text);

      this.props.setActiveOrganizationId(id);
      this.props.onReceiveQueue(extractAppealsAndAmaTasks(tasks));
    }
  );

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
        message: 'Loading cases...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load cases'
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
  onReceiveQueue,
  setActiveOrganizationId
}, dispatch);

export default (connect(null, mapDispatchToProps)(OrganizationQueueLoadingScreen): React.ComponentType<Params>);
