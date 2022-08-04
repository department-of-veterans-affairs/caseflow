import _ from 'lodash';
import { connect } from 'react-redux';
import React from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

class ContinueButtonUnconnected extends React.Component {

  render = () => {
    const {
      splitReason,
      originalReason,
    } = this.props;

    const continueDisabled = _.isEqual(
      splitReason, `${originalReason }hi`
    );

    return <span>
      <Link to="/review_split">
        <Button
          name="continue-split"
          onClick={this.onClickContinue}
          disabled={continueDisabled}
        >
        Continue
        </Button>
      </Link>

    </span>;
  }
}

ContinueButtonUnconnected.propTypes = {
  splitReason: PropTypes.string,
  originalReason: PropTypes.string,
  formType: PropTypes.string,
  claimId: PropTypes.string,
  history: PropTypes.object,
};

const ContinueButton = connect(
  (state) => ({
    claimId: state.claimId,
    formType: state.formType,
    splitReason: PropTypes.string,
    originalReason: PropTypes.string,
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
            window.location.href = `/queue/appeals/${this.props.claimId}/edit`;
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

