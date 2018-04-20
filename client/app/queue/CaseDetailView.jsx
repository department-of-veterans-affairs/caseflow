import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import AppealDetail from './AppealDetail';
import AppellantDetail from './AppellantDetail';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import TabWindow from '../components/TabWindow';
import { fullWidth, CATEGORIES, DECISION_TYPES } from './constants';
import { LOGO_COLORS } from '../constants/AppConstants';
import ReaderLink from './ReaderLink';

import {
  pushBreadcrumb,
  resetBreadcrumbs
} from './uiReducer/uiActions';

const headerStyling = css({ marginBottom: '0.5rem' });

class CaseDetailView extends React.PureComponent {
  componentDidMount = () => {
    // TODO: Add logic here that fetches the appeal if we don't yet have it.


    this.props.resetBreadcrumbs();
    this.props.pushBreadcrumb({
      breadcrumb: 'Your Queue',
      path: '/'
    }, {
      breadcrumb: this.props.appeal.attributes.veteran_full_name,
      path: `/appeals/${this.props.vacolsId}`
    });
  }

  // TODO: Unset activeCase when we unmount this component.

  showCaseDetails = () => {
    console.log(this.props);

    const appeal = this.props.appeal.attributes;

    const tabs = [{
      label: 'Appeal',
      page: <AppealDetail appeal={this.props.appeal} analyticsSource={CATEGORIES.CASE_DETAIL} />
    }, {
      label: `Appellant (${appeal.appellant_full_name || appeal.veteran_full_name})`,
      page: <AppellantDetail appeal={this.props.appeal} analyticsSource={CATEGORIES.CASE_DETAIL} />
    }];

    return <AppSegment filledBackground>
      <h1 className="cf-push-left" {...css(headerStyling, fullWidth)}>
        {appeal.veteran_full_name} ({appeal.vbms_id})
      </h1>
      <ReaderLink
        vacolsId={this.props.vacolsId}
        message="Open documents in Caseflow Reader"
        analyticsSource={CATEGORIES.CASE_DETAIL}
        redirectUrl={window.location.pathname}
        taskType="Draft Decision" />
      <TabWindow
        name="casedetail-tabwindow"
        tabs={tabs} />
    </AppSegment>;
  };

  render = () => {
    return this.props.appeal ? this.showCaseDetails() : <LoadingDataDisplay
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading case details...'
      }} />;
  };
}

CaseDetailView.propTypes = {
  vacolsId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.caseDetail.activeCase
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  pushBreadcrumb,
  resetBreadcrumbs
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(CaseDetailView));
