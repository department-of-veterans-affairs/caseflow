import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import ApiUtil from '../util/ApiUtil';
import { getMinutesToMilliseconds } from '../util/DateUtil';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';

import {
  onReceiveQueue,
  setQueueConfig
} from './QueueActions';

import {
  setActiveOrganization
} from './uiReducer/uiActions';
import WindowUtil from '../util/WindowUtil';

class OrganizationQueueLoadingScreen extends React.PureComponent {
  createOrgQueueLoadPromise = () => {
    const requestOptions = {
      timeout: { response: getMinutesToMilliseconds(5) }
    };

    return ApiUtil.get(this.props.urlToLoad, requestOptions).
      then(
        (response) => {
          const {
            id,
            type,
            organization_name: organizationName,
            is_vso: isVso,
            user_can_bulk_assign: userCanBulkAssign,
            queue_config: queueConfig
          } = response.body;

          this.props.setActiveOrganization(id, type, organizationName, isVso, userCanBulkAssign);
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
      Please <a onClick={WindowUtil.reloadWithPOST}>refresh the page</a> and try again.
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

OrganizationQueueLoadingScreen.propTypes = {
  children: PropTypes.node,
  onReceiveQueue: PropTypes.func,
  setActiveOrganization: PropTypes.func,
  setQueueConfig: PropTypes.func,
  urlToLoad: PropTypes.string
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveQueue,
  setActiveOrganization,
  setQueueConfig
}, dispatch);

export default (connect(null, mapDispatchToProps)(OrganizationQueueLoadingScreen));
