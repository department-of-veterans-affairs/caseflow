import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import { createOrgQueueLoadPromise } from './utils';

import {
  onReceiveQueue
} from './QueueActions';

import {
  setActiveOrganization
} from './uiReducer/uiActions';

class OrganizationQueueLoadingScreen extends React.PureComponent {
  reload = () => window.location.reload();

  render = () => {
    const failStatusMessageChildren = <div>
      It looks like Caseflow was unable to load your cases.<br />
      Please <a onClick={this.reload}>refresh the page</a> and try again.
    </div>;

    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={() => {
        return createOrgQueueLoadPromise(this.props, this.props.urlToLoad)}
      }
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
