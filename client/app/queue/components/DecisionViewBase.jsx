import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { withRouter } from 'react-router-dom';
import { css } from 'glamor';

import {
  pushBreadcrumb,
  popBreadcrumb,
  highlightInvalidFormItems,
  showModal,
  hideModal
} from '../uiReducer/uiActions';
import {
  checkoutStagedAppeal,
  resetDecisionOptions
} from '../QueueActions';

import Breadcrumbs from './BreadcrumbManager';
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

    updateBreadcrumbs = () => {
      if (!this.state.wrapped.getBreadcrumb) {
        return;
      }

      const breadcrumb = this.state.wrapped.getBreadcrumb();
      const renderedCrumbs = _.map(this.props.breadcrumbs, 'path');
      const newCrumbIdx = renderedCrumbs.indexOf(breadcrumb.path);

      if (newCrumbIdx === -1) {
        this.props.pushBreadcrumb(breadcrumb);
      } else if (newCrumbIdx < (renderedCrumbs.length - 1)) {
        // if returning to an earlier page, remove later crumbs
        const crumbsToPop = renderedCrumbs.length - (newCrumbIdx + 1);

        this.props.popBreadcrumb(crumbsToPop);
      }
    };

    getFooterButtons = () => {
      const cancelButton = {
        classNames: ['cf-btn-link'],
        callback: this.props.showModal,
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
        willNeverBeLoading: true,
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

      this.props.hideModal();
      this.props.resetDecisionOptions();
      _.each(stagedAppeals, this.props.checkoutStagedAppeal);

      history.push('/queue');
    }

    goToStep = (url) => {
      this.props.history.push(url);
      window.scrollTo(0, 0);
    };

    goToPrevStep = () => {
      const { breadcrumbs, prevStep } = this.props;
      const prevStepHook = _.get(this.state.wrapped, 'goToPrevStep');

      if (!prevStepHook || prevStepHook()) {
        // If the wrapped component has no prevStep prop, return to the
        // path of the previous page (the penultimate breadcrumb)
        const prevStepCrumb = breadcrumbs[breadcrumbs.length - 2];
        const prevStepUrl = prevStep || prevStepCrumb.path;

        if (!prevStep) {
          this.props.popBreadcrumb();
        }

        return this.props.history.push(prevStepUrl);
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
      this.updateBreadcrumbs();

      if (prevProps.savePending && !this.props.savePending) {
        if (this.props.saveSuccessful) {
          this.props.history.push(this.getNextStepUrl());
        } else {
          this.props.highlightInvalidFormItems(true);
        }
      }
    }

    render = () => <React.Fragment>
      <Breadcrumbs />
      {this.props.modal && <div className="cf-modal-scroll">
        <Modal
          title="Are you sure you want to cancel?"
          buttons={[{
            classNames: ['usa-button', 'cf-btn-link'],
            name: 'Return to editing',
            onClick: this.props.hideModal
          }, {
            classNames: ['usa-button-secondary', 'usa-button-hover', 'usa-button-warning'],
            name: 'Yes, cancel',
            onClick: this.cancelCheckoutFlow
          }]}
          closeHandler={this.props.hideModal}>
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
    ..._.pick(state.ui, 'breadcrumbs', 'modal'),
    ..._.pick(state.ui.saveState, 'savePending', 'saveSuccessful'),
    stagedAppeals: _.keys(state.queue.stagedChanges.appeals)
  });
  const mapDispatchToProps = (dispatch) => bindActionCreators({
    pushBreadcrumb,
    popBreadcrumb,
    highlightInvalidFormItems,
    showModal,
    hideModal,
    checkoutStagedAppeal,
    resetDecisionOptions
  }, dispatch);

  return withRouter(connect(mapStateToProps, mapDispatchToProps)(WrappedComponent));
}
