import React from 'react';
import PropTypes from 'prop-types';
import CaseflowDistributionContent from '../components/CaseflowDistributionContent';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import {
  loadLevers
} from '../reducers/Levers/leversActions';

class CaseflowDistributionApp extends React.PureComponent {

  // FOR PROOF OF CONCEPT; REMOVE
  componentDidMount() {
    this.props.loadLevers(this.props.acd_levers);
  }

  render() {

    return (
      <div>
        <div> {/* Wrapper*/}
          <CaseflowDistributionContent
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
