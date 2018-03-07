import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';

import {
  pushBreadcrumb,
  highlightInvalidFormItems
} from '../QueueActions';

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
        return [{}, {}];
      }

      const [backButton, nextButton] = getButtons();

      _.defaults(backButton, {
        classNames: ['cf-btn-link'],
        callback: this.goToPrevStep
      });
      _.defaults(nextButton, {
        classNames: ['cf-right-side'],
        callback: this.goToNextStep
      });

      return [backButton, nextButton];
    };

    goToPrevStep = () => {
      const prevStepHook = this.wrapped && this.wrapped.goToPrevStep;

      if (!prevStepHook) {
        return this.props.goToPrevStep();
      }

      if (prevStepHook()) {
        this.props.goToPrevStep();
      }
    };

    goToNextStep = () => {
      const validation = this.wrapped && this.wrapped.validateForm;

      if (validation && validation()) {
        this.props.goToNextStep();
      } else {
        this.props.highlightInvalidFormItems(true);
      }
    };

    render = () => <React.Fragment>
      <Breadcrumbs />
      <AppSegment filledBackground>
        <ComponentToWrap ref={this.getWrappedComponentRef} {...this.passthroughProps()} />
      </AppSegment>
      <DecisionViewFooter buttons={this.getFooterButtons()} />
    </React.Fragment>;
  }

  WrappedComponent.displayName = `DecisionViewBase(${getDisplayName(WrappedComponent)})`;

  const mapStateToProps = (state) => _.pick(state.queue.ui, 'breadcrumbs');
  const mapDispatchToProps = (dispatch) => bindActionCreators({
    pushBreadcrumb,
    highlightInvalidFormItems
  }, dispatch);

  return connect(mapStateToProps, mapDispatchToProps)(WrappedComponent);
}
