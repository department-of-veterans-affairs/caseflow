import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import { ENDPOINT_NAMES } from './analytics';
import ApiUtil from '../util/ApiUtil';
import { onReceiveAssignments } from '../reader/CaseSelect/CaseSelectActions';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import * as Constants from './constants';

export class CaseSelectLoadingScreen extends React.Component {
  createLoadPromise = () => {
    // We append an unneeded query param to avoid caching the json object. If we get thrown
    // to a page outside of the SPA and then hit back, we want the cached version of this
    // page to be the HTML page, not the JSON object.
    return ApiUtil.get('/reader/appeal?json', {}, ENDPOINT_NAMES.APPEAL_DETAILS).then((response) => {
      const returnedObject = JSON.parse(response.text);

      this.props.onReceiveAssignments(returnedObject.cases);
    });
  }

  render() {
    const failStatusMessageChildren = <div>
        It looks like Caseflow was unable to load the welcome page.<br />
        Please <a href="">refresh the page</a> and try again.
    </div>;

    return <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingScreenProps={{
        wrapInAppSegment: false,
        spinnerColor: Constants.READER_COLOR,
        message: 'Loading cases in Reader...'
      }}
      failStatusMessageProps={{
        wrapInAppSegment: false,
        title: 'Unable to load the welcome page'
      }}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.props.children}
    </LoadingDataDisplay>;
  }
}

const mapStateToProps = (state) => ({
  assignments: state.caseSelect.assignments,
  assignmentsLoaded: state.caseSelect.assignmentsLoaded
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    onReceiveAssignments
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(CaseSelectLoadingScreen);
