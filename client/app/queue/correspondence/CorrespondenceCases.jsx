import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import ApiUtil from '../../util/ApiUtil';
import { loadCorrespondenceConfig } from './correspondenceReducer/correspondenceActions';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { sprintf } from 'sprintf-js';
import CorrespondenceTableBuilder from './CorrespondenceTableBuilder';
import Alert from '../../components/Alert';

// import {
//   initialAssignTasksToUser,
//   initialCamoAssignTasksToVhaProgramOffice
// } from '../QueueActions';

class CorrespondenceCases extends React.PureComponent {

  // now grabs tasks and loads into redux store
  getCorrespondenceConfig() {
    return ApiUtil.get(this.props.configUrl).then((response) => {
      const returnedObject = response.body;
      const correspondenceConfig = returnedObject.correspondence_config;

      this.props.loadCorrespondenceConfig(correspondenceConfig);
    }).
      catch((err) => {
        // allow HTTP errors to fall on the floor via the console.
        console.error(new Error(`Problem with GET /queue/correspondence?json ${err}`));
      });
  }

  // load task info on page load
  componentDidMount() {
    // Retry the request after a delay
    setTimeout(() => {
      this.getCorrespondenceConfig();
    }, 1000);
  }

  render = () => {
    const {
      organizations,
      currentAction,
      veteranInformation

    } = this.props;

    let vetName = '';

    if (Object.keys(veteranInformation).length > 0) {
      vetName = `${veteranInformation.veteran_name.first_name.trim()} ${
        veteranInformation.veteran_name.last_name.trim()}`;
    }

    return (
      <React.Fragment>
        <AppSegment filledBackground>
          {(Object.keys(veteranInformation).length > 0) &&
            currentAction.action_type === 'DeleteReviewPackage' &&
          <Alert type="success" title={sprintf(COPY.CORRESPONDENCE_TITLE_REMOVE_PACKAGE_BANNER, vetName)}
            message={COPY.CORRESPONDENCE_MESSAGE_REMOVE_PACKAGE_BANNER} scrollOnAlert={false} />}
          {this.props.correspondenceConfig &&
          <CorrespondenceTableBuilder />}
        </AppSegment>
      </React.Fragment>
    );
  }
}

CorrespondenceCases.propTypes = {
  organizations: PropTypes.array,
  loadCorrespondenceConfig: PropTypes.func,
  correspondenceConfig: PropTypes.object,
  currentAction: PropTypes.object,
  veteranInformation: PropTypes.object,
  configUrl: PropTypes.string
};

const mapStateToProps = (state) => ({
  correspondenceConfig: state.intakeCorrespondence.correspondenceConfig,
  currentAction: state.reviewPackage.lastAction,
  veteranInformation: state.reviewPackage.veteranInformation
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    loadCorrespondenceConfig,
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CorrespondenceCases);
