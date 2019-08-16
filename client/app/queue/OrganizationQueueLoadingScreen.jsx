import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import ApiUtil from '../util/ApiUtil';
import { getMinutesToMilliseconds } from '../util/DateUtil';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import { extractAppealsAndAmaTasks } from './utils';

import {
  onReceiveQueue,
  setQueueConfig
} from './QueueActions';

import {
  setActiveOrganization
} from './uiReducer/uiActions';

class OrganizationQueueLoadingScreen extends React.PureComponent {
  reload = () => window.location.reload();

  createOrgQueueLoadPromise = () => {
    const requestOptions = {
      timeout: { response: getMinutesToMilliseconds(5) }
    };

    return ApiUtil.get(this.props.urlToLoad, requestOptions).
      then(
        (response) => {
          const {
            tasks: { data: tasks },
            id,
            organization_name: organizationName,
            is_vso: isVso,
            queue_config: queueConfig
          } = response.body;

          this.props.setActiveOrganization(id, organizationName, isVso);
          this.props.onReceiveQueue(extractAppealsAndAmaTasks(tasks));
          this.props.setQueueConfig(queueConfig);
        }
      ).
      catch(() => {
        // handle frontend error
      });
  }

  render = () => {
    const failStatusMessageChildren = <div>
      It looks like Caseflow was unable to load your cases.<br />
      Please <a onClick={this.reload}>refresh the page</a> and try again.
    </div>;

    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={() => this.createOrgQueueLoadPromise()}
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
  setActiveOrganization,
  setQueueConfig
}, dispatch);

export default (connect(null, mapDispatchToProps)(OrganizationQueueLoadingScreen));
