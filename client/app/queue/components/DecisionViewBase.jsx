import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { withRouter } from 'react-router-dom';
import { css } from 'glamor';

import {
  highlightInvalidFormItems,
  showModal,
  hideModal
} from '../uiReducer/uiActions';
import {
  checkoutStagedAppeal,
  resetDecisionOptions
} from '../QueueActions';

import COPY from '../../../COPY.json';
import DecisionViewFooter from './DecisionViewFooter';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Modal from '../../components/Modal';

const getDisplayName = (WrappedComponent) => {
  return WrappedComponent.displayName || WrappedComponent.name || 'WrappedComponent';
};

const defaultTopLevelProps = {
  continueBtnText: 'Continue',
  hideCancelButton: false,
  modalName: 'cancelCheckout'
};

export default function decisionViewBase(ComponentToWrap, topLevelProps = defaultTopLevelProps) {
  class WrappedComponent extends React.Component {
    constructor(props) {
      super(props);

      this.state = { wrapped: null };
    }

    getWrappedComponentRef = (ref) => this.setState({ wrapped: ref });

    componentDidMount = () => this.props.highlightInvalidFormItems(false);

    showModal = () => this.props.showModal(this.props.modalName);
    hideModal = () => this.props.hideModal(this.props.modalName);

    getFooterButtons = () => {
      const buttons = [{
        classNames: ['cf-btn-link'],
        callback: this.showModal,
        name: 'cancel-button',
        displayText: 'Cancel',
        willNeverBeLoading: true
      }, {
        classNames: ['cf-right-side', 'cf-next-step'],
        callback: this.goToNextStep,
        loading: this.props.savePending,
        name: 'next-button',
        displayText: this.props.continueBtnText,
        loadingText: 'Submitting...',
        styling: css({ marginLeft: '1rem' })
      }, {
        classNames: ['cf-right-side', 'cf-prev-step', 'usa-button-outline'],
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

      this.hideModal();
      this.props.resetDecisionOptions();
      _.each(stagedAppeals, this.props.checkoutStagedAppeal);

      history.push(`/queue/appeals/${appealId}`);
    }

    getPrevStepUrl = () => _.invoke(this.state.wrapped, 'getPrevStepUrl') || this.props.prevStep;
    getNextStepUrl = () => _.invoke(this.state.wrapped, 'getNextStepUrl') || this.props.nextStep;

    goToPrevStep = () => {
      const { goToPrevStep: prevStepHook = null } = this.state.wrapped;

      if (!prevStepHook || prevStepHook()) {
        return this.props.history.push(this.getPrevStepUrl());
      }
    };

    goToNextStep = () => {
      // This handles moving to the next step in the flow. The wrapped
      // component's validateForm is used to trigger highlighting form
      // elements. If present, the wrapped goToNextStep hook dispatches
      // a proceed/invalid action asynchronously, which this responds
      // to in componentDidUpdate.
      const {
        validateForm: validation = null,
        goToNextStep: nextStepHook = null
      } = this.state.wrapped;

      if (!validation || !validation()) {
        return this.props.highlightInvalidFormItems(true);
      }
      this.props.highlightInvalidFormItems(false);

      if (!nextStepHook) {
        return this.props.history.push(this.getNextStepUrl());
      }

      const hookResult = nextStepHook();

      // nextStepHook may return a Promise, in which case do nothing here.
      if (hookResult === true) {
        return this.props.history.push(this.getNextStepUrl());
      }
    };

    componentDidUpdate = (prevProps) => {
      if (prevProps.savePending && !this.props.savePending) {
        if (this.props.saveSuccessful) {
          this.props.history.push(this.getNextStepUrl());
        } else {
          this.props.highlightInvalidFormItems(true);
        }
      }
    }

    render = () => <React.Fragment>
      {this.props.modal && <div className="cf-modal-scroll">
        <Modal
          title="Are you sure you want to cancel?"
          buttons={[{
            classNames: ['usa-button', 'cf-btn-link'],
            name: 'Return to editing',
            onClick: this.hideModal
          }, {
            classNames: ['usa-button-secondary', 'usa-button-hover', 'usa-button-warning'],
            name: 'Yes, cancel',
            onClick: this.cancelFlow
          }]}
          closeHandler={this.hideModal}>
          {COPY.MODAL_CANCEL_ATTORNEY_CHECKOUT}
        </Modal>
      </div>}
      <AppSegment filledBackground>
        <ComponentToWrap ref={this.getWrappedComponentRef} {...this.props} />
      </AppSegment>
      <DecisionViewFooter buttons={this.getFooterButtons()} />
    </React.Fragment>;
  }

  WrappedComponent.displayName = `DecisionViewBase(${getDisplayName(WrappedComponent)})`;

  const mapStateToProps = (state) => {
    const { savePending, saveSuccessful } = state.ui.saveState;
    const { modalName } = topLevelProps;

    return {
      modal: state.ui.modal[modalName],
      savePending,
      saveSuccessful,
      stagedAppeals: Object.keys(state.queue.stagedChanges.appeals),
      ...topLevelProps
    };
  };
  const mapDispatchToProps = (dispatch) => bindActionCreators({
    highlightInvalidFormItems,
    showModal,
    hideModal,
    checkoutStagedAppeal,
    resetDecisionOptions
  }, dispatch);

  return withRouter(connect(mapStateToProps, mapDispatchToProps)(WrappedComponent));
}
