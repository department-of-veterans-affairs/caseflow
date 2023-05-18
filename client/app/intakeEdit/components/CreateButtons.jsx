import { connect } from 'react-redux';
import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import IntakeAppealContext from './IntakeAppealContext';
import { StateContext } from '../IntakeEditFrame';
import Button from '../../components/Button';
import COPY from '../../../COPY';
import { splitAppeal } from '../../intake/actions/intake';

class CancelButtonUnconnected extends React.PureComponent {
  render = () => {
    const onClick = this.appealForm;

    return <Button
      id="cancel-edit"
      linkStyling
      willNeverBeLoading
      styling={{ style: { float: 'left' } }}
      onClick={onClick}
    >
      Cancel
    </Button>;
  }

  appealForm = () => {
    if (this.props.formType === 'appeal') {
      window.location.href = `/queue/appeals/${this.props.claimId}`;
    } else {
      this.props.history.push('/cancel');
    }
  }
}

CancelButtonUnconnected.propTypes = {
  history: PropTypes.object,
  formType: PropTypes.string,
  claimId: PropTypes.string
};

const CancelButton = connect(
  (state) => ({
    formType: state.formType,
    claimId: state.claimId
  })
)(CancelButtonUnconnected);

class BackButtonUnconnected extends React.PureComponent {
  render = () => {

    return (
      <Button
        id="cancel-back"
        linkStyling
        willNeverBeLoading
        classNames={['usa-button-secondary']}
        onClick={
          () => {
            if (this.props.formType === 'appeal') {
              window.location.href = `/appeals/${this.props.claimId}/edit/create_split`;
            } else {
              this.props.history.push('/cancel');
            }
          }
        }
      >
      Back
      </Button>);
  }
}

BackButtonUnconnected.propTypes = {
  history: PropTypes.object,
  formType: PropTypes.string,
  claimId: PropTypes.string
};

const BackButton = connect(
  (state) => ({
    formType: state.formType,
    claimId: state.claimId
  })
)(BackButtonUnconnected);

class SplitButtonUnconnected extends React.PureComponent {

  handleSplitSubmit = (appeal, payloadInfo, userCssId) => {
    const cleanedIssues = [];

    // since selectedIssues come in as a Hash, clean to only have request issue id selected
    Object.entries(payloadInfo.selectedIssues).forEach((item) => {
      // if the value is true, push the request issue id
      if (item[1] === true) {
        cleanedIssues.push(item[0]);
      }
    });

    const response = this.props.splitAppeal(appeal.id, cleanedIssues,
      payloadInfo.reason, payloadInfo.otherReason, userCssId);

    response.then(() => {
      window.location.href = `/queue/appeals/${this.props.claimId}`;
    });
  }
  render() {

    return (
      <IntakeAppealContext.Consumer>
        {(appealInfoUserArray) => (
          <StateContext.Consumer>
            {(payloadInfo) => (
              <Button
                id="button-submit-update"
                classNames={['cf-submit usa-button']}
                // on click button sends claim id for dummy data
                onClick={() => this.handleSplitSubmit(appealInfoUserArray[0], payloadInfo, appealInfoUserArray[1])}>
                { COPY.CORRECT_REQUEST_ISSUES_SPLIT_APPEAL }
              </Button>

            )}
          </StateContext.Consumer>
        )}
      </IntakeAppealContext.Consumer>

    );

  }
}

SplitButtonUnconnected.propTypes = {
  history: PropTypes.object,
  formType: PropTypes.string,
  claimId: PropTypes.string,
  splitAppeal: PropTypes.func,
  user: PropTypes.string,
};

const mapStateToProps = (state) => ({
  formType: state.formType,
  claimId: state.claimId
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  splitAppeal
}, dispatch);

const SplitButton = connect(
  mapStateToProps,
  mapDispatchToProps)(SplitButtonUnconnected);

export default class CreateButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelButton history={this.props.history} />
      <BackButton history={this.props.history} />
      <SplitButton history={this.props.history} />
    </div>
}

CreateButtons.propTypes = {
  history: PropTypes.object
};
