import React from 'react';
import PropTypes from 'prop-types';
import CaseflowDistributionContent from '../components/CaseflowDistributionContent';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import {
  initialLoad
} from '../reducers/Levers/leversActions';

class CaseflowDistributionApp extends React.PureComponent {
  constructor(props) {
    super(props);
    this.props.initialLoad(this.props.acdLeversForStore);
  }

  render() {
    return (
      <div>
        <div> {/* Wrapper*/}
          <CaseflowDistributionContent
            levers = {this.props.acd_levers}
            saveChanges = {() => {}}
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
  acd_levers: PropTypes.object,
  acd_history: PropTypes.array,
  user_is_an_acd_admin: PropTypes.bool,
  leverStore: PropTypes.any,
  sectionTitles: PropTypes.array,
  initialLoad: PropTypes.func,
  acdLeversForStore: PropTypes.object
};

// eslint-disable-next-line no-unused-vars
const mapStateToProps = (state) => ({
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    initialLoad
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseflowDistributionApp);
