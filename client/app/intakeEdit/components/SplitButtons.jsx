import _ from 'lodash';
import { connect } from 'react-redux';
import React, { useContext } from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import { RequestIssueContext, StateContext } from '../IntakeEditFrame';
import { Link } from 'react-router-dom';

const ContinueButtonUnconnected = (props) => {
  const { selectedIssues, reason } = useContext(StateContext);
  const allIssuesChecked = _.every(_.values(selectedIssues), (value) => {
    return value === true;
  });
  const noIssueSelected = _.every(_.values(selectedIssues), (value) => {
    return value === false;
  });
  const everyIssueSelected = _.keys(selectedIssues).length === props.requestIssueCount;

  const continueDisabled = (noIssueSelected || _.isEmpty(reason) || (everyIssueSelected && allIssuesChecked));

  return (
    <span>
      {(continueDisabled ? (
        <Button
          name="continue-split"
          disabled={continueDisabled}
        >
        Continue
        </Button>
      ) : (
        <Link to="/review_split">
          <Button
            name="continue-split"
            disabled={continueDisabled}
          >
        Continue
          </Button>
        </Link>
      ))}

    </span>
  );
};

ContinueButtonUnconnected.propTypes = {
  history: PropTypes.object,
  formType: PropTypes.string,
  claimId: PropTypes.string,
  requestIssueCount: PropTypes.number
};

const ContinueButton = connect(
  (state) => ({
    formType: state.formType,
    claimId: state.claimId
  }),
)(ContinueButtonUnconnected);

class CancelSplitButtonUnconnected extends React.PureComponent {

  handleClick = () => {
    window.location.href = `/queue/appeals/${this.props.claimId}`;
  }

  render = () => {
    return <Button
      id="cancel-edit"
      linkStyling
      willNeverBeLoading
      styling={{ style: { float: 'left' } }}
      onClick={this.handleClick}
    >
      Cancel
    </Button>;
  }
}

CancelSplitButtonUnconnected.propTypes = {
  history: PropTypes.object,
  formType: PropTypes.string,
  claimId: PropTypes.string
};

const CancelSplitButton = connect(
  (state) => ({
    formType: state.formType,
    claimId: state.claimId
  })
)(CancelSplitButtonUnconnected);

export default class SplitButtons extends React.PureComponent {
  render = () =>
    <RequestIssueContext.Consumer>
      {(requestIssueCount) => (
        <div>
          <CancelSplitButton history={this.props.history} />
          <ContinueButton history={this.props.history} requestIssueCount={requestIssueCount} />
        </div>
      )}
    </RequestIssueContext.Consumer>
}

SplitButtons.propTypes = {
  history: PropTypes.object
};

