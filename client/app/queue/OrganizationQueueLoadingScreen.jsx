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
  setActiveOrganization
} from './uiReducer/uiActions';

class OrganizationQueueLoadingScreen extends React.PureComponent {
  // TODO: Short-circuit this request if we already have the tasks for this organization's queue.
  createLoadPromise = () => ApiUtil.get(this.props.urlToLoad, { timeout: { response: 5 * 60 * 1000 } }).then(
    (response) => {
      const {
        tasks: { data: tasks },
        id,
        organization_name: organizationName,
        is_vso: isVso
      } = JSON.parse(response.text);

      this.props.setActiveOrganization(id, organizationName, isVso);
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
  setActiveOrganization
}, dispatch);

export default (connect(null, mapDispatchToProps)(OrganizationQueueLoadingScreen));
