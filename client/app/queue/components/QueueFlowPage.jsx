import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { withRouter } from 'react-router-dom';
import { css } from 'glamor';
import PropTypes from 'prop-types';

import {
  highlightInvalidFormItems,
  showModal,
  hideModal
} from '../uiReducer/uiActions';
import {
  checkoutStagedAppeal,
  resetDecisionOptions
} from '../QueueActions';

import COPY from '../../../COPY';
import DecisionViewFooter from './DecisionViewFooter';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Modal from '../../components/Modal';

class QueueFlowPage extends React.PureComponent {
  componentDidMount = () => {
    this.props.highlightInvalidFormItems(false);

    this.blockTransitions();
  }

  blockTransitions = () => this.unblockTransitions = this.props.history.block((location) => {
    const { pathname } = location;
    const newPathInCheckoutFlow = /^\/queue\/appeals\/[a-zA-Z0-9-]+(?:\/\S+)?/;

    if (!newPathInCheckoutFlow.exec(pathname) && pathname !== '/queue') {
      return `${COPY.MODAL_CANCEL_ATTORNEY_CHECKOUT_PROMPT} ${this.cancelAttorneyCheckoutMsg()}`;
    }

    return true;
  });

  cancelAttorneyCheckoutMsg = () => {
    return COPY.MODAL_CANCEL_ATTORNEY_CHECKOUT_SPECIAL_ISSUES;
  }

  withUnblockedTransition = (callback = _.noop) => {
    this.unblockTransitions();
    callback();
    this.blockTransitions();
  }

  componentWillUnmount = () => this.unblockTransitions();

  getFooterButtons = () => {
    const buttons = [{
      classNames: ['cf-btn-link'],
      callback: () => this.props.showModal('cancelCheckout'),
      name: 'cancel-button',
      displayText: 'Cancel',
      willNeverBeLoading: true
    }, {
      classNames: ['cf-right-side'],
      callback: this.goToNextStep,
      loading: this.props.savePending,
      name: 'next-button',
      disabled: this.props.disableNext,
      displayText: this.props.continueBtnText,
      loadingText: 'Submitting...',
      styling: css({ marginLeft: '1rem' })
    }, {
      classNames: ['cf-right-side', 'cf-prev-step', 'usa-button-secondary'],
      callback: this.props.hideCancelButton ? this.cancelFlow : this.goToPrevStep,
      name: 'back-button',
      displayText: this.props.hideCancelButton ? 'Cancel' : 'Back',
      willNeverBeLoading: true
    }];

    return this.props.hideCancelButton ? buttons.slice(1) : buttons;
  }

  cancelFlow = () => {
    const {
      history,
      stagedAppeals,
      appealId
    } = this.props;

    this.props.hideModal('cancelCheckout');
    this.props.resetDecisionOptions();
    _.each(stagedAppeals, this.props.checkoutStagedAppeal);

    this.withUnblockedTransition(
      () => history.replace(`/queue/appeals/${appealId}`)
    );
  }

  getPrevStepUrl = () => {
    const {
      getPrevStepUrl,
      appealId,
      prevStep
    } = this.props;

    return (getPrevStepUrl && getPrevStepUrl()) || prevStep || `/queue/appeals/${appealId}`;
  }

  getNextStepUrl = () => {
    const {
      getNextStepUrl,
      nextStep
    } = this.props;

    return (getNextStepUrl && getNextStepUrl()) || nextStep;
  }

  goToPrevStep = () => {
    const { goToPrevStep: prevStepHook } = this.props;

    if (!prevStepHook || prevStepHook()) {
      return this.props.history.replace(this.getPrevStepUrl());
    }
  };

  goToNextStep = () => {
    // This handles moving to the next step in the flow. The wrapped
    // component's validateForm is used to trigger highlighting form
    // elements. If present, the wrapped goToNextStep hook dispatches
    // a proceed/invalid action asynchronously, which this responds
    // to in componentDidUpdate.
    const {
      validateForm,
      goToNextStep: nextStepHook
    } = this.props;

    if (validateForm && !validateForm()) {
      return this.props.highlightInvalidFormItems(true);
    }
    this.props.highlightInvalidFormItems(false);

    if (!nextStepHook) {
      return this.props.history.replace(this.getNextStepUrl());
    }

    // nextStepHook may return a Promise, in which case do nothing here.
    if (nextStepHook() === true) {
      return this.props.history.replace(this.getNextStepUrl());
    }
  };

  componentDidUpdate = (prevProps) => {
    if (prevProps.savePending && !this.props.savePending) {
      if (this.props.saveSuccessful) {
        this.props.history.replace(this.getNextStepUrl());
      } else {
        this.props.highlightInvalidFormItems(true);
      }
    }
  }

  render = () => <React.Fragment>
    {this.props.cancelCheckoutModal && <div className="cf-modal-scroll">
      <Modal
        title={COPY.MODAL_CANCEL_ATTORNEY_CHECKOUT_PROMPT}
        buttons={[{
          classNames: ['usa-button', 'cf-btn-link'],
          name: 'Return to editing',
          onClick: () => this.props.hideModal('cancelCheckout')
        }, {
          classNames: ['usa-button-secondary', 'usa-button-hover', 'usa-button-warning'],
          name: 'Yes, cancel',
          onClick: this.cancelFlow
        }]}
        closeHandler={() => this.props.hideModal('cancelCheckout')}>
        {this.cancelAttorneyCheckoutMsg()}
      </Modal>
    </div>}
    <AppSegment filledBackground>
      {this.props.children}
    </AppSegment>
    <DecisionViewFooter buttons={this.getFooterButtons()} />
  </React.Fragment>;
}

QueueFlowPage.propTypes = {
  children: PropTypes.node.isRequired,
  cancelCheckoutModal: PropTypes.bool,
  continueBtnText: PropTypes.string,
  disableNext: PropTypes.bool,
  hideCancelButton: PropTypes.bool,
  history: PropTypes.object,
  validateForm: PropTypes.func,
  goToNextStep: PropTypes.func,
  goToPrevStep: PropTypes.func,
  getNextStepUrl: PropTypes.func,
  getPrevStepUrl: PropTypes.func,
  appealId: PropTypes.string.isRequired,
  nextStep: PropTypes.string,
  prevStep: PropTypes.string,
  savePending: PropTypes.bool,
  saveSuccessful: PropTypes.bool,
  stagedAppeals: PropTypes.array,
  // provided by mapDispatchToProps
  highlightInvalidFormItems: PropTypes.func,
  showModal: PropTypes.func,
  hideModal: PropTypes.func,
  checkoutStagedAppeal: PropTypes.func,
  resetDecisionOptions: PropTypes.func
};

QueueFlowPage.defaultProps = {
  continueBtnText: 'Continue',
  disableNext: false,
  hideCancelButton: false,
  validateForm: null,
  goToNextStep: null,
  goToPrevStep: null,
  getNextStepUrl: null,
  getPrevStepUrl: null
};

const mapStateToProps = (state, props) => {
  const { savePending, saveSuccessful } = state.ui.saveState;

  return {
    cancelCheckoutModal: state.ui.modals.cancelCheckout,
    savePending,
    saveSuccessful,
    stagedAppeals: Object.keys(state.queue.stagedChanges.appeals),
    ...props
  };
};
const mapDispatchToProps = (dispatch) => bindActionCreators({
  highlightInvalidFormItems,
  showModal,
  hideModal,
  checkoutStagedAppeal,
  resetDecisionOptions
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(QueueFlowPage));
