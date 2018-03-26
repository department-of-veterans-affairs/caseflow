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

import Breadcrumbs from './BreadcrumbManager';
import DecisionViewFooter from './DecisionViewFooter';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

const getDisplayName = (WrappedComponent) => {
  return WrappedComponent.displayName || WrappedComponent.name || 'WrappedComponent';
};

export default function decisionViewBase(ComponentToWrap) {
  class WrappedComponent extends React.Component {
    getWrappedComponentRef = (ref) => this.wrapped = ref;

    componentDidMount = () => {
      this.props.highlightInvalidFormItems(false);

      if (!this.wrapped.getBreadcrumb) {
        return;
      }

      const { state } = this.props.history.location;
      // Here, state.crumb is the wrapped component's prevStep prop
      // (defined in this.goToPrevStep). Step pages can have one of
      // { breadcrumb, breadcrumb + prevStep, neither }
      const appendBreadcrumb = _.get(state, 'crumb', true);

      if (appendBreadcrumb) {
        const breadcrumb = this.wrapped.getBreadcrumb();

        if (breadcrumb && _.last(this.props.breadcrumbs).path !== breadcrumb.path) {
          this.props.pushBreadcrumb(breadcrumb);
        }
      }
    };

    getFooterButtons = () => {
      const getButtons = _.get(this.wrapped, 'getFooterButtons');

      if (!getButtons) {
        return [];
      }

      const [backButton, nextButton] = getButtons();

      _.defaults(backButton, {
        classNames: ['cf-btn-link', 'cf-prev-step'],
        callback: this.goToPrevStep
      });
      _.defaults(nextButton, {
        classNames: ['cf-right-side', 'cf-next-step'],
        callback: this.goToNextStep,
        disabled: this.props.savePending
      });

      return [backButton, nextButton];
    };

    goToStep = (url, state) => {
      // todo: confirmation message, trigger reloading tasks
      this.props.history.push(url, state);
      window.scrollTo(0, 0);
    };

    goToPrevStep = () => {
      const { breadcrumbs, prevStep } = this.props;
      const prevStepHook = _.get(this.wrapped, 'goToPrevStep');

      if (!prevStepHook || prevStepHook()) {
        // If the wrapped component has no prevStep prop, return to the
        // path of the previous page (the penultimate breadcrumb)
        const prevStepCrumb = breadcrumbs[breadcrumbs.length - 2];
        const prevStepUrl = prevStep || prevStepCrumb.path;

        if (!prevStep) {
          this.props.popBreadcrumb();
        }

        return this.goToStep(prevStepUrl, { crumb: prevStep });
      }
    };

    goToNextStep = () => {
      // This handles moving to the next step in the flow. The wrapped
      // component's validateForm is used to trigger highlighting form
      // elements. If present, the wrapped goToNextStep hook dispatches
      // a proceed/invalid action asynchronously, which this responds
      // to in componentDidUpdate.
      const validation = _.get(this.wrapped, 'validateForm');
      const nextStepHook = _.get(this.wrapped, 'goToNextStep');

      if (!validation || !validation()) {
        return this.props.highlightInvalidFormItems(true);
      }

      if (!nextStepHook) {
        return this.goToStep(this.props.nextStep);
      }

      const hookResult = nextStepHook();

      // nextStepHook may return a Promise, in which case do nothing here.
      if (hookResult === true) {
        return this.goToStep(this.props.nextStep);
      }
    };

    componentDidUpdate = (prevProps) => {
      if (prevProps.savePending && !this.props.savePending) {
        if (this.props.saveSuccessful) {
          this.goToStep(this.props.nextStep);
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

  const mapStateToProps = (state) => _.pick(state.ui, 'breadcrumbs', 'savePending', 'saveSuccessful');
  const mapDispatchToProps = (dispatch) => bindActionCreators({
    pushBreadcrumb,
    popBreadcrumb,
    highlightInvalidFormItems
  }, dispatch);

  return withRouter(connect(mapStateToProps, mapDispatchToProps)(WrappedComponent));
}
