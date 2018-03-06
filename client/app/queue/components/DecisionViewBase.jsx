import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';

import {
  pushBreadcrumb,
  highlightMissingFormItems
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
      this.props.highlightMissingFormItems(false);

      if (this.wrapped.getBreadcrumb) {
        const breadcrumb = this.wrapped.getBreadcrumb();

        if (breadcrumb && _.last(this.props.breadcrumbs).path !== breadcrumb.path) {
          this.props.pushBreadcrumb(breadcrumb);
        }
      }
    };

    getFooterButtons = () => this.wrapped.getFooterButtons ? this.wrapped.getFooterButtons() : [];

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
    highlightMissingFormItems
  }, dispatch);

  return connect(mapStateToProps, mapDispatchToProps)(WrappedComponent);
}
