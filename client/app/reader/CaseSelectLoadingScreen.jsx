import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import { ENDPOINT_NAMES } from './analytics';
import ApiUtil from '../util/ApiUtil';
import { onReceiveAssignments } from '../reader/CaseSelect/CaseSelectActions';
import StatusMessage from '../components/StatusMessage';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import * as Constants from './constants';

export class CaseSelectLoadingScreen extends React.Component {
  constructor() {
    super();
    this.state = {};
  }

  componentDidMount = () => {
    if (this.props.assignments) {

      // We append an unneeded query param to avoid caching the json object. If we get thrown
      // to a page outside of the SPA and then hit back, we want the cached version of this
      // page to be the HTML page, not the JSON object.
      const loadPromise = ApiUtil.get('/reader/appeal?json', {}, ENDPOINT_NAMES.APPEAL_DETAILS).then((response) => {
        const returnedObject = JSON.parse(response.text);

        this.props.onReceiveAssignments(returnedObject.cases);
      });

      this.setState({
        promiseStartTimeMs: Date.now(),
        loadPromise
      });
    }
  }

  render() {
    // We create this.loadPromise in componentDidMount().
    // componentDidMount() is only called after the component is inserted into the DOM,
    // which means that render() will be called beforehand. My inclination was to use
    // componentWillMount() instead, but React docs tell us not to introduce side-effects
    // in that method. I don't know why that's a bad idea. But this approach lets us
    // keep the side effects in componentDidMount().
    if (!this.state.loadPromise) {
      return null;
    }

    const failStatusMessageChildren = <div>
        It looks like Caseflow was unable to load the welcome page.<br />
        Please <a href="">refresh the page</a> and try again.
    </div>;

    const loadingDataDisplay = <LoadingDataDisplay
      loadPromise={this.state.loadPromise}
      promiseStartTimeMs={this.state.promiseStartTimeMs}
      loadingScreenProps={{
        spinnerColor: Constants.READER_COLOR,
        message: 'Loading cases in Reader...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load the welcome page'
      }}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.props.children}
    </LoadingDataDisplay>;

    return <div className="usa-grid">
      <div className="cf-app">
        {loadingDataDisplay}
      </div>
    </div>;
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
