import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import ApiUtil from '../../util/ApiUtil';
import { loadVetCorrespondence } from './correspondenceReducer/correspondenceActions';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { css } from 'glamor';
import CorrespondenceTable from './CorrespondenceTable';
import QueueOrganizationDropdown from '../components/QueueOrganizationDropdown';

// import {
//   initialAssignTasksToUser,
//   initialCamoAssignTasksToVhaProgramOffice
// } from '../QueueActions';

class CorrespondenceCases extends React.PureComponent {

  // grabs correspondences and loads into intakeCorrespondence redux store.
  getVeteransWithCorrespondence() {
    return ApiUtil.get('/queue/correspondence?json').then((response) => {
      const returnedObject = response.body;
      const vetCorrespondences = returnedObject.vetCorrespondences;

      this.props.loadVetCorrespondence(vetCorrespondences);
    }).
      catch((err) => {
        // allow HTTP errors to fall on the floor via the console.
        console.error(new Error(`Problem with GET /queue/correspondence?json ${err}`));
      });
  }

  // load veteran correspondence info on page load
  componentDidMount() {
    // Retry the request after a delay
    setTimeout(() => {
      this.getVeteransWithCorrespondence();
    }, 1000);
  }

  render = () => {
    const {
      organizations
    } = this.props;

    return (
      <React.Fragment>
        <AppSegment filledBackground>
          <h1 {...css({ display: 'inline-block' })}>{COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_CORRESPONDENCE_CASES}</h1>
          <QueueOrganizationDropdown organizations={organizations} />
          {this.props.vetCorrespondences &&
          <CorrespondenceTable
            vetCorrespondences={this.props.vetCorrespondences}
          />
          }
        </AppSegment>
      </React.Fragment>
    );
  }
}

CorrespondenceCases.propTypes = {
  organizations: PropTypes.array,
  loadVetCorrespondence: PropTypes.func,
  vetCorrespondences: PropTypes.array
};

const mapStateToProps = (state) => ({
  vetCorrespondences: state.intakeCorrespondence.vetCorrespondences
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    loadVetCorrespondence
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CorrespondenceCases);
