import React from 'react';
import PropTypes from 'prop-types';
import CaseflowDistributionContent from '../components/CaseflowDistributionContent';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import {
  loadLevers
} from '../reducers/Levers/leversActions';
import ApiUtil from '../../util/ApiUtil';

class CaseflowDistributionApp extends React.PureComponent {

  // load the lever and history info from database
  // the GET request can be moved into an action if needed
  componentDidMount() {
    // use ApiUtil to get the JSON info from our route
    ApiUtil.get('/acd-controls-test-route?json').then((response) => {
      // unpack the returned response
      const returnedObject = response.body;
      const acdLevers = returnedObject.acdLevers;
      const acdHistory = returnedObject.acdHistory;

      // load lever and history into redux store using actions
      this.props.loadLevers(acdLevers);
      // load initial history action goes here
    }).
      catch((err) => {
        console.error(new Error(`Problem with GET /acd-controls-test-route?json ${err}`));
      });
  }

  render() {

    return (
      <div>
        <div> {/* Wrapper*/}
          <CaseflowDistributionContent
            loadedLevers = {this.props.loadedLevers}
            levers = {this.props.acd_levers}
            saveChanges = {[]}
            formattedHistory={this.props.acd_history}
            leverStore={this.props.leverStore}
            isAdmin = {this.props.user_is_an_acd_admin}
            sectionTitles = {this.props.sectionTitles}
          />
        </div>
      </div>
    );

  }
}

CaseflowDistributionApp.propTypes = {
  acd_levers: PropTypes.array,
  acd_history: PropTypes.array,
  user_is_an_acd_admin: PropTypes.bool,
  leverStore: PropTypes.any,
  sectionTitles: PropTypes.array,
  loadLevers: PropTypes.func,
  loadedLevers: PropTypes.object
};

// FOR PROOF OF CONCEPT; REMOVE!
const mapStateToProps = (state) => ({
  loadedLevers: state.caseDistributionLevers.loadedLevers
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    loadLevers
  }, dispatch)
)

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseflowDistributionApp);
