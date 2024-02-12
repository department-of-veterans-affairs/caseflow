import React from 'react';
import PropTypes from 'prop-types';
import CaseDistributionContent from '../components/CaseDistributionContent';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import {
  loadLevers,
  loadHistory,
  setUserIsAcdAdmin
} from '../reducers/levers/leversActions';

class CaseDistributionApp extends React.PureComponent {
  constructor(props) {
    super(props);
    this.props.loadLevers(this.props.acdLeversForStore);
    this.props.loadHistory(this.props.acd_history);
    this.props.setUserIsAcdAdmin(this.props.user_is_an_acd_admin);
  }

  render() {
    return (
      <div>
        <div>
          <CaseDistributionContent />
        </div>
      </div>
    );

  }
}

CaseDistributionApp.propTypes = {
  acdLeversForStore: PropTypes.object,
  acd_history: PropTypes.array,
  user_is_an_acd_admin: PropTypes.bool,
  loadLevers: PropTypes.func,
  loadHistory: PropTypes.func,
  setUserIsAcdAdmin: PropTypes.func,
};

// eslint-disable-next-line no-unused-vars
const mapStateToProps = (state) => ({
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    loadLevers,
    loadHistory,
    setUserIsAcdAdmin
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseDistributionApp);
