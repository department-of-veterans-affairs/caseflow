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

import DecisionViewFooter from './DecisionViewFooter';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Modal from '../../components/Modal';

const getDisplayName = (WrappedComponent) => {
  return WrappedComponent.displayName || WrappedComponent.name || 'WrappedComponent';
};

export default function decisionViewBase(ComponentToWrap) {
  class WrappedComponent extends React.Component {
    constructor(props) {
      super(props);

      this.state = { wrapped: {} };
    }

    getWrappedComponentRef = (ref) => this.setState({ wrapped: ref })

    componentDidMount = () => this.props.highlightInvalidFormItems(false);

    getFooterButtons = () => {
      const cancelButton = {
        classNames: ['cf-btn-link'],
        callback: () => this.props.showModal('cancelCheckout'),
        name: 'cancel-button',
        displayText: 'Cancel',
        willNeverBeLoading: true
      };
      const nextButton = {
        classNames: ['cf-right-side', 'cf-next-step'],
        callback: this.goToNextStep,
        loading: this.props.savePending,
        name: 'next-button',
        displayText: 'Continue',
        loadingText: 'Submitting...',
        styling: css({ marginLeft: '1rem' })
      };
      const backButton = {
        classNames: ['cf-right-side', 'cf-prev-step', 'usa-button-outline'],
        callback: this.goToPrevStep,
        name: 'back-button',
        displayText: 'Back',
        willNeverBeLoading: true
      };

      return [cancelButton, nextButton, backButton];
    };

    cancelCheckoutFlow = () => {
      const {
        history,
        stagedAppeals
      } = this.props;

      this.props.hideModal('cancelCheckout');
      this.props.resetDecisionOptions();
      _.each(stagedAppeals, this.props.checkoutStagedAppeal);

      // todo: checkout flow now starts from within case details page--return there on cancel?
      history.push('/queue');
    }

    goToPrevStep = () => {
      const { prevStep } = this.props;
      const prevStepHook = _.get(this.state.wrapped, 'goToPrevStep');

      if (!prevStepHook || prevStepHook()) {
        return this.props.history.push(prevStep);
      }
    };

    getNextStepUrl = () => _.invoke(this.state.wrapped, 'getNextStepUrl') || this.props.nextStep;

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
      {this.props.cancelCheckoutModal && <div className="cf-modal-scroll">
        <Modal
          title="Are you sure you want to cancel?"
          buttons={[{
            classNames: ['usa-button', 'cf-btn-link'],
            name: 'Return to editing',
            onClick: () => this.props.hideModal('cancelCheckout')
          }, {
            classNames: ['usa-button-secondary', 'usa-button-hover', 'usa-button-warning'],
            name: 'Yes, cancel',
            onClick: this.cancelCheckoutFlow
          }]}
          closeHandler={() => this.props.hideModal('cancelCheckout')}>
          All changes made to this page will be lost, except for the adding,
          editing, and deleting of issues.
        </Modal>
      </div>}
      <AppSegment filledBackground>
        <ComponentToWrap ref={this.getWrappedComponentRef} {...this.props} />
      </AppSegment>
      <DecisionViewFooter buttons={this.getFooterButtons()} />
    </React.Fragment>;
  }

  WrappedComponent.displayName = `DecisionViewBase(${getDisplayName(WrappedComponent)})`;

  const mapStateToProps = (state) => ({
    cancelCheckoutModal: state.ui.modal.cancelCheckout,
    ..._.pick(state.ui.saveState, 'savePending', 'saveSuccessful'),
    stagedAppeals: _.keys(state.queue.stagedChanges.appeals)
  });
  const mapDispatchToProps = (dispatch) => bindActionCreators({
    highlightInvalidFormItems,
    showModal,
    hideModal,
    checkoutStagedAppeal,
    resetDecisionOptions
  }, dispatch);

  return withRouter(connect(mapStateToProps, mapDispatchToProps)(WrappedComponent));
}
