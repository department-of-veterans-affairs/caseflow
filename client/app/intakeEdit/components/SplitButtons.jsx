import _ from 'lodash';
import { connect } from 'react-redux';
import React, { useContext } from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import { StateContext } from '../IntakeEditFrame';
import { Link } from 'react-router-dom';

const ContinueButtonUnconnected = () => {
  const { selectedIssues, reason } = useContext(StateContext);

  const continueDisabled = (_.isEmpty(selectedIssues) || _.isEmpty(reason));

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

const ContinueButton = connect(
  () => ({
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
    <div>
      <CancelSplitButton history={this.props.history} />
      <ContinueButton history={this.props.history} />
    </div>
}

SplitButtons.propTypes = {
  history: PropTypes.object
};

