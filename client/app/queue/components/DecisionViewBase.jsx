import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { withRouter } from 'react-router-dom';

import {
  pushBreadcrumb,
  popBreadcrumb,
  highlightInvalidFormItems
} from '../uiReducer/uiActions';
import { getRedirectUrl } from '../utils';

import Breadcrumbs from './BreadcrumbManager';
import DecisionViewFooter from './DecisionViewFooter';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

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
      const getButtons = _.get(this.state.wrapped, 'getFooterButtons');

      if (!getButtons) {
        return [];
      }

      const [backButton, nextButton] = getButtons();

      _.defaults(nextButton, {
        classNames: ['cf-right-side', 'cf-next-step'],
        callback: this.goToNextStep,
        loading: this.props.savePending,
        name: 'next-button'
      });
      _.defaults(backButton, {
        classNames: ['cf-btn-link', 'cf-prev-step'],
        callback: this.goToPrevStep,
        name: 'back-button'
      });

      backButton.displayText = `< ${backButton.displayText}`;

      return [backButton, nextButton];
    };

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
        const prevStepUrl = getRedirectUrl() || prevStep || prevStepCrumb.path;

        if (!prevStep) {
          this.props.popBreadcrumb();
        }

        return this.goToStep(prevStepUrl);
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

      if (!nextStepHook) {
        return this.goToStep(this.getNextStepUrl());
      }

      const hookResult = nextStepHook();

      // nextStepHook may return a Promise, in which case do nothing here.
      if (hookResult === true) {
        return this.goToStep(this.getNextStepUrl());
      }
    };

    componentDidUpdate = (prevProps) => {
      this.updateBreadcrumbs();

      if (prevProps.savePending && !this.props.savePending) {
        if (this.props.saveSuccessful) {
          this.goToStep(this.getNextStepUrl());
        } else {
          this.props.highlightInvalidFormItems(true);
        }
      }
    }

    render = () => <React.Fragment>
      <Breadcrumbs />
      <AppSegment filledBackground>
        <ComponentToWrap ref={this.getWrappedComponentRef} {...this.props} />
      </AppSegment>
      <DecisionViewFooter buttons={this.getFooterButtons()} />
    </React.Fragment>;
  }

  WrappedComponent.displayName = `DecisionViewBase(${getDisplayName(WrappedComponent)})`;

  const mapStateToProps = (state) => ({
    ..._.pick(state.ui, 'breadcrumbs'),
    ..._.pick(state.ui.saveState, 'savePending', 'saveSuccessful')
  });
  const mapDispatchToProps = (dispatch) => bindActionCreators({
    pushBreadcrumb,
    popBreadcrumb,
    highlightInvalidFormItems
  }, dispatch);

  return withRouter(connect(mapStateToProps, mapDispatchToProps)(WrappedComponent));
}
