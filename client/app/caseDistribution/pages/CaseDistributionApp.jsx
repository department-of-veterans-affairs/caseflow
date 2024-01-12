import React from 'react';
import PropTypes from 'prop-types';
import CaseDistributionContent from '../components/CaseDistributionContent';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import {
  loadLevers,
  setUserIsAcdAdmin
} from '../reducers/levers/leversActions';

class CaseDistributionApp extends React.PureComponent {
  constructor(props) {
    super(props);
    this.props.loadLevers(this.props.acdLeversForStore, this.props.acd_history);
    this.props.setUserIsAcdAdmin(this.props.user_is_an_acd_admin);
  }

  render() {
    return (
      <div>
        <div> {/* Wrapper*/}
          <CaseDistributionContent
            levers = {this.props.acd_levers}
            leverStore={this.props.leverStore}
          />
        </div>
      </div>
    );

  }
}

CaseDistributionApp.propTypes = {
  acd_levers: PropTypes.object,
  acd_history: PropTypes.array,
  user_is_an_acd_admin: PropTypes.bool,
  leverStore: PropTypes.any,
  loadLevers: PropTypes.func,
  setUserIsAcdAdmin: PropTypes.func,
  acdLeversForStore: PropTypes.object
};

// eslint-disable-next-line no-unused-vars
const mapStateToProps = (state) => ({
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    loadLevers,
    setUserIsAcdAdmin
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseDistributionApp);
