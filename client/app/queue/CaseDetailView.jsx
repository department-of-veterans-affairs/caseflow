import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import AppealDetail from './AppealDetail';
import AppellantDetail from './AppellantDetail';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import TabWindow from '../components/TabWindow';
import { fullWidth, CATEGORIES } from './constants';
import { LOGO_COLORS } from '../constants/AppConstants';
import ReaderLink from './ReaderLink';
import ApiUtil from '../util/ApiUtil';

import { clearActiveCase, setActiveCase } from './CaseDetail/CaseDetailActions';

const headerStyling = css({ marginBottom: '0.5rem' });
const subHeadStyling = css({ marginBottom: '2rem' });
const backLinkStyling = css({
  float: 'left',
  marginTop: '-3rem'
});

class CaseDetailView extends React.PureComponent {
  componentWillUnmount = () => this.props.clearActiveCase();

  vacolsId = () => this.props.match.params.vacolsId;

  loadCaseDetails = () => {
    if (this.props.appeal) {
      return Promise.resolve();
    }

    return ApiUtil.get(`/queue/appeals/${this.vacolsId()}`).then((response) => {
      const resp = JSON.parse(response.text);

      this.props.setActiveCase(resp.appeal);
    });
  }

  showCaseDetails = () => {
    if (!this.props.appeal) {
      return null;
    }

    const appeal = this.props.appeal.attributes;

    const tabs = [{
      label: 'Appeal',
      page: <AppealDetail appeal={this.props.appeal} analyticsSource={CATEGORIES.CASE_DETAIL} />
    }, {
      label: `Appellant (${appeal.appellant_full_name || appeal.veteran_full_name})`,
      page: <AppellantDetail appeal={this.props.appeal} analyticsSource={CATEGORIES.CASE_DETAIL} />
    }];

    return <React.Fragment>
      <div {...backLinkStyling}>
        <Link to="/" onClick={this.props.clearActiveCase}>
          &lt; Back to {appeal.veteran_full_name} ({appeal.vbms_id})'s Case List
        </Link>
      </div>
      <AppSegment filledBackground>
        <h1 className="cf-push-left" {...css(headerStyling, fullWidth)}>
          {appeal.veteran_full_name} ({appeal.vbms_id})
        </h1>
        <p className="cf-lead-paragraph" {...subHeadStyling}>
          Docket Number: {appeal.docket_number}, Assigned to Location {appeal.location_code}
        </p>
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
      </AppSegment>
    </React.Fragment>;
  };

  render = () => {
    const failStatusMessageChildren = <div>
      Caseflow was unable to load case details for this case.<br />
      Please <a onClick={this.reload}>refresh the page</a> and try again.
    </div>;

    return <LoadingDataDisplay
      createLoadPromise={this.loadCaseDetails}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading case details...'
      }}
      failStatusMessageProps={{ title: 'Unable to load case details' }}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.showCaseDetails()}
    </LoadingDataDisplay>;
  }
}

const mapStateToProps = (state) => ({
  appeal: state.caseDetail.activeCase
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearActiveCase,
  setActiveCase
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(CaseDetailView));
