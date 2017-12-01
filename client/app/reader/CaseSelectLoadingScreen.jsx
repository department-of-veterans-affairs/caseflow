import React from 'react';
import { bindActionCreators } from 'redux';
import { ENDPOINT_NAMES } from './analytics';
import ApiUtil from '../util/ApiUtil';
import { onReceiveAssignments, onInitialCaseLoadingFail } from './actions';
import { connect } from 'react-redux';
import StatusMessage from '../components/StatusMessage';
import LoadingScreen from '../components/LoadingScreen';
import * as Constants from './constants';
import _ from 'lodash';

export class CaseSelectLoadingScreen extends React.Component {
  componentDidMount = () => {
    // We append an unneeded query param to avoid caching the json object. If we get thrown
    // to a page outside of the SPA and then hit back, we want the cached version of this
    // page to be the HTML page, not the JSON object.
    if (this.props.assignments) {
      this.props.onInitialCaseLoadingFail(false);

      ApiUtil.get('/reader/appeal?json', {}, ENDPOINT_NAMES.APPEAL_DETAILS).then((response) => {
        const returnedObject = JSON.parse(response.text);

        this.props.onReceiveAssignments(returnedObject.cases);
      }, this.props.onInitialCaseLoadingFail);
    }
  }

  render() {
    if (this.props.assignmentsLoaded) {
      return this.props.children;
    }

    return <div className="usa-grid">
        <div className="cf-app">
          {this.props.initialCaseLoadingFail ?
            <StatusMessage
              title="Unable to load the welcome page">
              It looks like Caseflow was unable to load the welcome page.<br />
              Please <a href="">refresh the page</a> and try again.
              </StatusMessage> :
              <LoadingScreen
                spinnerColor={Constants.READER_COLOR}
                message="Loading cases in Reader..."/>
          }
        </div>
      </div>;
  }
}

const mapStateToProps = (state) => ({
  ..._.pick(state.readerReducer, 'initialCaseLoadingFail'),
  assignments: state.readerReducer.assignments,
  assignmentsLoaded: state.readerReducer.assignmentsLoaded
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    onInitialCaseLoadingFail,
    onReceiveAssignments
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(CaseSelectLoadingScreen);
