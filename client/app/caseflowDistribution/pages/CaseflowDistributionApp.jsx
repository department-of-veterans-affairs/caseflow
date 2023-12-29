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

  // FOR PROOF OF CONCEPT; REMOVE
  // test for getting JSON payload from new route
  componentDidMount() {
    ApiUtil.get('/acd-controls-test-route?json').then((response) => {
      const returnedObject = response.body;
      const acdLevers = returnedObject.acdLevers;
      const acdHistory = returnedObject.acdHistory;
      // console.log(`levers from new method (levers): ${JSON.stringify(acdLevers, null, 2)}`)
      // console.log(`levers from new method (history): ${JSON.stringify(acdHistory, null, 2)}`);

      this.props.loadLevers(acdLevers);
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
  loadLevers: PropTypes.func
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
