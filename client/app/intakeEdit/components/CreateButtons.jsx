import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';
import update from 'immutability-helper';
import pluralize from 'pluralize';
import PropTypes from 'prop-types';

import Button from '../../components/Button';
import COPY from '../../../COPY';
import { sprintf } from 'sprintf-js';

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
    return <Button
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
    </Button>;
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
  render = () => {
    return <Button
      id="button-submit-update"
      classNames={['cf-submit usa-button']}
      onClick={
        () => {
          window.location.href = `/queue/appeals/${this.props.claimId}`;
        }
      }
    >
      { COPY.CORRECT_REQUEST_ISSUES_SPLIT_APPEAL }
    </Button>;
  }
}

SplitButtonUnconnected.propTypes = {
  history: PropTypes.object,
  formType: PropTypes.string,
  claimId: PropTypes.string
};

const SplitButton = connect(
  (state) => ({
    formType: state.formType,
    claimId: state.claimId
  })
)(SplitButtonUnconnected);

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
