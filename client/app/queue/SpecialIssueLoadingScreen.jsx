import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';
import { getMinutesToMilliseconds } from '../util/DateUtil';

import { setSpecialIssues } from './QueueActions';
import WindowUtil from '../util/WindowUtil';

class SpecialIssueLoadingScreen extends React.PureComponent {

  createLoadPromise = () => {
    const requestOptions = {
      timeout: { response: getMinutesToMilliseconds(5) }
    };

    return ApiUtil.get(
      `/appeals/${this.props.appealExternalId}/special_issues`, requestOptions).then(
      (response) => {
        // eslint-disable-next-line no-unused-vars, camelcase
        const { appeal_id, id, ...specialIssues } = response.body;

        this.props.setSpecialIssues(specialIssues);
      }
    );
  }

  render = () => {
    const failStatusMessageChildren = <div>
      It looks like Caseflow was unable to load this case's special issues<br />
      Please <a onClick={WindowUtil.reloadWithPOST}>refresh the page</a> and try again.
    </div>;

    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading cases...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load special issues'
      }}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.props.children}
    </LoadingDataDisplay>;

    return <div className="usa-grid">
      {loadingDataDisplay}
    </div>;
  };
}

SpecialIssueLoadingScreen.propTypes = {
  appealExternalId: PropTypes.string,
  children: PropTypes.node,
  setSpecialIssues: PropTypes.func
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setSpecialIssues
}, dispatch);

export default (connect(null, mapDispatchToProps)(SpecialIssueLoadingScreen));
