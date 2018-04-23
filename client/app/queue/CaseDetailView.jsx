import { css } from 'glamor';
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
import ApiUtil from '../util/ApiUtil';

import {
  pushBreadcrumb,
  resetBreadcrumbs
} from './uiReducer/uiActions';

const headerStyling = css({ marginBottom: '0.5rem' });

class CaseDetailView extends React.PureComponent {
  vacolsId = () => this.props.match.params.vacolsId;

  loadCaseDetails = () => {
    if (this.props.appeal) {
      return Promise.resolve();
    }

    return ApiUtil.get(`/appeals/${this.vacolsId()}`).then((response) => {
      const resp = JSON.parse(response.text);

      console.log("API response");
      console.log(resp);
    });
  }

  loadQueue = () => {
    Promise.resolve();
  };

  createLoadPromise = () => Promise.all([
    this.loadCaseDetails(),
    this.loadQueue()
  ]);

  componentDidMount = () => {
    this.props.resetBreadcrumbs();
    this.props.pushBreadcrumb({
      breadcrumb: 'Your Queue',
      path: '/'
    }, {
      breadcrumb: this.props.appeal.attributes.veteran_full_name,
      path: `/appeals/${this.vacolsId()}`
    });
  }

  // TODO: Unset activeCase when we unmount this component.

  showCaseDetails = () => {
    // console.log(this.props);

    if (!this.props.appeal) {
      return;
    }

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
        vacolsId={this.vacolsId()}
        message="Open documents in Caseflow Reader"
        analyticsSource={CATEGORIES.CASE_DETAIL}
        redirectUrl={window.location.pathname}
        taskId="DUMMY ID TO MAKE LINK WORK"
        taskType="Draft Decision" />
      <TabWindow
        name="casedetail-tabwindow"
        tabs={tabs} />
    </AppSegment>;
  };

  render = () => {
    // console.log(this.props);

    const failStatusMessageChildren = <div>
      Caseflow was unable to load case details for this case.<br />
      Please <a onClick={this.reload}>refresh the page</a> and try again.
    </div>;

    return <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading case details...'
      }}
      failStatusMessageProps={{title: 'Unable to load case details'}}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.props.showCaseDetails}
    </LoadingDataDisplay>;
  }
}

const mapStateToProps = (state, ownProps) => ({
  appeal: state.caseDetail.activeCase
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  pushBreadcrumb,
  resetBreadcrumbs
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(CaseDetailView));
