import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { withRouter } from 'react-router-dom';

import {
  pushBreadcrumb,
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
    passthroughProps = () => _.omit(this.props, 'pushBreadcrumb');
    getWrappedComponentRef = (ref) => this.wrapped = ref;

    componentDidMount = () => {
      this.props.highlightInvalidFormItems(false);

      if (this.wrapped.getBreadcrumb) {
        const breadcrumb = this.wrapped.getBreadcrumb();

        if (breadcrumb && _.last(this.props.breadcrumbs).path !== breadcrumb.path) {
          this.props.pushBreadcrumb(breadcrumb);
        }
      }
    };

    getFooterButtons = () => {
      const getButtons = this.wrapped && this.wrapped.getFooterButtons;

      if (!getButtons) {
        return [];
      }

      const [backButton, nextButton] = getButtons();

      _.defaults(backButton, {
        classNames: ['cf-btn-link'],
        callback: this.goToPrevStep
      });
      _.defaults(nextButton, {
        classNames: ['cf-right-side'],
        callback: this.goToNextStep,
        disabled: this.props.pendingSave
      });

      return [backButton, nextButton];
    };

    goToStep = (url) => {
      this.props.history.push(url);
      window.scrollTo(0, 0);
    };

    goToPrevStep = () => {
      const prevStepHook = this.wrapped && this.wrapped.goToPrevStep;

      if (!prevStepHook || (prevStepHook && prevStepHook())) {
        return this.goToStep(this.props.prevStep);
      }
    };

    goToNextStep = () => {
      // This handles moving to the next step in the flow. The wrapped
      // component's validateForm is used to synchronously trigger highlighting
      // form elements based on its return value. If present, the wrapped
      // goToNextStep hook dispatches a proceed/invalid action asynchronously,
      // which this responds to in componentDidUpdate.
      const validation = this.wrapped && this.wrapped.validateForm;
      const nextStepHook = this.wrapped && this.wrapped.goToNextStep;

      if (!validation || (validation && !validation())) {
        return this.props.highlightInvalidFormItems(true);
      }

      if (!nextStepHook) {
        return this.goToStep(this.props.nextStep);
      }

      const hookResult = nextStepHook();

      // nextStepHook may return a Promise, in which case do nothing here.
      if (hookResult && hookResult === true) {
        return this.goToStep(this.props.nextStep);
      }
    };

    componentDidUpdate = (prevProps) => {
      if (prevProps.pendingSave && !this.props.pendingSave) {
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
        <ComponentToWrap ref={this.getWrappedComponentRef} {...this.passthroughProps()} />
      </AppSegment>
      <DecisionViewFooter buttons={this.getFooterButtons()} />
    </React.Fragment>;
  }

  WrappedComponent.displayName = `DecisionViewBase(${getDisplayName(WrappedComponent)})`;

  const mapStateToProps = (state) => _.pick(state.ui, 'breadcrumbs', 'pendingSave', 'saveSuccessful');
  const mapDispatchToProps = (dispatch) => bindActionCreators({
    pushBreadcrumb,
    highlightInvalidFormItems
  }, dispatch);

  return withRouter(connect(mapStateToProps, mapDispatchToProps)(WrappedComponent));
}
