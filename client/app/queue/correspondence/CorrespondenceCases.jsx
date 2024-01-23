import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import ApiUtil from '../../util/ApiUtil';
import { loadCorrespondenceTasks } from './correspondenceReducer/correspondenceActions';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';
import CorrespondenceTable from './CorrespondenceTable';
import QueueOrganizationDropdown from '../components/QueueOrganizationDropdown';
import Alert from '../../components/Alert';

// import {
//   initialAssignTasksToUser,
//   initialCamoAssignTasksToVhaProgramOffice
// } from '../QueueActions';

class CorrespondenceCases extends React.PureComponent {

  // now grabs tasks and loads into redux store
  getCorrespondenceTasks() {
    return ApiUtil.get('/queue/correspondence/?json').then((response) => {
      const returnedObject = response.body;
      const correspondenceTasks = returnedObject.correspondenceTasks;

      this.props.loadCorrespondenceTasks(correspondenceTasks);
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
      this.getCorrespondenceTasks();
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
          <h1 {...css({ display: 'inline-block' })}>{COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_CORRESPONDENCE_CASES}</h1>
          <QueueOrganizationDropdown organizations={organizations} />
          {this.props.correspondenceTasks &&
          <CorrespondenceTable
            correspondenceTasks={this.props.correspondenceTasks}
          />
          }
        </AppSegment>
      </React.Fragment>
    );
  }
}

CorrespondenceCases.propTypes = {
  organizations: PropTypes.array,
  loadCorrespondenceTasks: PropTypes.func,
  correspondenceTasks: PropTypes.array,
  currentAction: PropTypes.object,
  veteranInformation: PropTypes.object
};

const mapStateToProps = (state) => ({
  correspondenceTasks: state.intakeCorrespondence.correspondenceTasks,
  currentAction: state.reviewPackage.lastAction,
  veteranInformation: state.reviewPackage.veteranInformation
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    loadCorrespondenceTasks,
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CorrespondenceCases);
