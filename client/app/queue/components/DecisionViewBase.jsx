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
  title: 'cancelCheckout',
  text: COPY.MODAL_CANCEL_ATTORNEY_CHECKOUT
};

export default function decisionViewBase(ComponentToWrap, topLevelProps = defaultTopLevelProps) {
  class WrappedComponent extends React.Component {
    constructor(props) {
      super(props);

      this.state = {
        wrapped: {},
        modalProps: topLevelProps
      };
    }

    getWrappedComponentRef = (ref) => this.setState({ wrapped: ref })

    componentDidMount = () => this.props.highlightInvalidFormItems(false);

    getModal = () => this.props.modal[this.state.modalProps.title];
    showModal = () => this.props.showModal(this.state.modalProps.title);
    hideModal = () => this.props.hideModal(this.state.modalProps.title);

    getFooterButtons = () => [{
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
      displayText: 'Continue',
      loadingText: 'Submitting...',
      styling: css({ marginLeft: '1rem' })
    }, {
      classNames: ['cf-right-side', 'cf-prev-step', 'usa-button-outline'],
      callback: this.goToPrevStep,
      name: 'back-button',
      displayText: 'Back',
      willNeverBeLoading: true
    }];

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
      const prevStepHook = _.get(this.state.wrapped, 'goToPrevStep');

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
      const validation = _.get(this.state.wrapped, 'validateForm');
      const nextStepHook = _.get(this.state.wrapped, 'goToNextStep');

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
      {this.getModal() && <div className="cf-modal-scroll">
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
          {this.state.modalProps.text}
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

    return {
      modal: state.ui.modal,
      savePending,
      saveSuccessful,
      stagedAppeals: Object.keys(state.queue.stagedChanges.appeals)
    }
  }
  const mapDispatchToProps = (dispatch) => bindActionCreators({
    highlightInvalidFormItems,
    showModal,
    hideModal,
    checkoutStagedAppeal,
    resetDecisionOptions
  }, dispatch);

  return withRouter(connect(mapStateToProps, mapDispatchToProps)(WrappedComponent));
}
