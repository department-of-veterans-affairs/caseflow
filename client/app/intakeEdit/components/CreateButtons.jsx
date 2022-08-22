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
              this.props.history.push('/create_split');
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

  handleSplitSubmit = (appeal, payloadInfo) => {
    this.props.splitAppeal(appeal.id, payloadInfo.selectedIssues,
      payloadInfo.reason, payloadInfo.otherReason);
    window.location.href = `/queue/appeals/${this.props.claimId}`;
  }
  render() {

    return (
      <IntakeAppealContext.Consumer>
        {(appeal) => (
          <StateContext.Consumer>
            {(payloadInfo) => (
              <div>
                <Button
                  id="button-submit-update"
                  classNames={['cf-submit usa-button']}
                  // on click button sends claim id for dummy data
                  onClick={() => this.handleSplitSubmit(appeal, payloadInfo)}>
                  { COPY.CORRECT_REQUEST_ISSUES_SPLIT_APPEAL }
                </Button>
              </div>

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
  splitAppeal: PropTypes.func
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
