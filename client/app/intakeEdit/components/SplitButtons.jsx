import _ from 'lodash';
import { connect } from 'react-redux';
import React, { useContext } from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import { StateContext } from '../IntakeEditFrame';

const ContinueButtonUnconnected = (props) => {
  const { selectedIssues, reason } = useContext(StateContext);

  const continueDisabled = (_.isEmpty(selectedIssues) || _.isEmpty(reason));
  const handleClick = () => {
    return (
      props.history.push('/review_split')
    );
  };

  return <span>

    <Button
      name="continue-split"
      onClick={handleClick}
      disabled={continueDisabled}
    >
        Continue
    </Button>

  </span>;
};

ContinueButtonUnconnected.propTypes = {
  formType: PropTypes.string,
  claimId: PropTypes.string,
  history: PropTypes.object,
};

const ContinueButton = connect(
  (state) => ({
    claimId: state.claimId,
    formType: state.formType,
  }),
)(ContinueButtonUnconnected);

class CancelSplitButtonUnconnected extends React.PureComponent {
  render = () => {
    return <Button
      id="cancel-edit"
      linkStyling
      willNeverBeLoading
      onClick={
        () => {
          if (this.props.formType === 'appeal') {
            window.location.href = `/queue/appeals/${this.props.claimId}`;
          } else {
            this.props.history.push('/cancel');
          }
        }
      }
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

