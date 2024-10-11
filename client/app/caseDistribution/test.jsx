/* eslint-disable max-lines */
/* eslint-disable react/prop-types */

import React from 'react';
import NavigationBar from '../components/NavigationBar';
import { BrowserRouter } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { LOGO_COLORS } from '../constants/AppConstants';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import CaseSearchLink from '../components/CaseSearchLink';
import ApiUtil from '../util/ApiUtil';
import Button from '../components/Button';
import Alert from 'app/components/Alert';
import CollapsibleTable from './components/CollapsibleTable';
import ResetButton from './components/testPage/ResetButton';
import COPY from '../../COPY';

class CaseDistributionTest extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      isReseedingAod: false,
      isReseedingNonAod: false,
      isReseedingAmaDocketGoals: false,
      isReseedingDocketPriority: false,
      isReturnLegacyAppeals: false,
      isFailReturnLegacyAppeals: false,
      isReseedingOptionalSeeds: false,
      isClearingAppeals: false,
      showLegacyAppealsAlert: false,
      showAlert: false,
      alertType: 'success',
    };
  }

  componentDidUpdate() {
    // Delay of 5 seconds
    setTimeout(() => {
      this.setState({ showAlert: false, showLegacyAppealsAlert: false });
    }, 5000);
  }

  reseedAod = () => {
    this.setState({ isReseedingAod: true });
    ApiUtil.post('/case_distribution_levers_tests/run_demo_aod_hearing_seeds').then(() => {
      this.setState({
        isReseedingAod: false,
        showAlert: true,
        alertMsg: '{COPY.TEST_RESEED_AOD_ALERTMSG}',
      });
    }, (err) => {
      console.warn(err);
      this.setState({
        isReseedingAod: false,
        showAlert: true,
        alertMsg: err,
        alertType: 'error',
      });
    });
  };

  resetAllAppeals = () => {
    this.setState({ isClearingAppeals: true });
    ApiUtil.post('/case_distribution_levers_tests/reset_all_appeals').then(() => {
      this.setState({
        isClearingAppeals: false,
        showAlert: true,
        alertMsg: 'Successfully cleared Ready-to-Distribute Appeals',
      });
    }, (err) => {
      console.warn(err);
      this.setState({
        isClearingAppeals: false,
        showAlert: true,
        alertMsg: err,
        alertType: 'error',
      });
    });
  };

  reseedNonAod = () => {
    this.setState({ isReseedingNonAod: true });
    ApiUtil.post('/case_distribution_levers_tests/run_demo_non_aod_hearing_seeds').then(() => {
      this.setState({
        isReseedingNonAod: false,
        showAlert: true,
        alertMsg: '{COPY.TEST_RESEED_NON_AOD_ALERTMSG}',
      });
    }, (err) => {
      console.warn(err);
      this.setState({
        isReseedingNonAod: false,
        showAlert: true,
        alertMsg: err,
        alertType: 'error',
      });
    });
  };

  reseedAmaDocketGoals = () => {
    this.setState({ isReseedingAmaDocketGoals: true });
    ApiUtil.post('/case_distribution_levers_tests/run-demo-ama-docket-goals').then(() => {
      this.setState({
        isReseedingAmaDocketGoals: false,
        showAlert: true,
        alertMsg: '{COPY.TEST_RESEED_AMA_DOCKET_GOALS_ALERTMSG}',
      });
    }, (err) => {
      console.warn(err);
      this.setState({
        isReseedingAmaDocketGoals: false,
        showAlert: true,
        alertMsg: err,
        alertType: 'error',
      });
    });
  };

  reseedDocketPriority = () => {
    this.setState({ isReseedingDocketPriority: true });
    ApiUtil.post('/case_distribution_levers_tests/run_demo_docket_priority').then(() => {
      this.setState({
        isReseedingDocketPriority: false,
        showAlert: true,
        alertMsg: '{COPY.TEST_RESEED_AMA_DOCKET_PRIORITY_ALERTMSG}',
      });
    }, (err) => {
      console.warn(err);
      this.setState({
        isReseedingDocketPriority: false,
        showAlert: true,
        alertMsg: err,
        alertType: 'error',
      });
    });
  };

  reseedNonSSCAVLJAppeals = () => {
    this.setState({ isReseedingNonSSCAVLJAppeals: true });
    ApiUtil.post('/case_distribution_levers_tests/run_demo_non_avlj_appeals').then(() => {
      this.setState({
        isReseedingNonSSCAVLJAppeals: false,
        showAlert: true,
        alertMsg: '{COPY.TEST_RESEED_NONSSCAVLJAPPEALS_ALERTMSG}',
      });
    }, (err) => {
      console.warn(err);
      this.setState({
        isReseedingNonSSCAVLJAppeals: false,
        showAlert: true,
        alertMsg: err,
        alertType: 'error',
      });
    });
  };

  returnLegacyAppealsToBoard = () => {
    this.setState({ isReturnLegacyAppeals: true });
    ApiUtil.post('/case_distribution_levers_tests/run_return_legacy_appeals_to_board').then(() => {
      this.setState({
        isReturnLegacyAppeals: false,
        showLegacyAppealsAlert: true,
        legacyAppealsAlertType: 'success',
        legacyAppealsAlertMsg: 'Successfully Completed Return Legacy Appeals To Board Job.',
      });
    }, (err) => {
      console.warn(err);
      this.setState({
        isReturnLegacyAppeals: false,
        showLegacyAppealsAlert: true,
        legacyAppealsAlertType: 'error',
        legacyAppealsAlertMsg: err
      });
    });
  };

  reseedGenericFullSuiteAppealsSeeds = () => {
    this.setState({ isReseedingOptionalSeeds: true });
    ApiUtil.post('/case_distribution_levers_tests/run_full_suite_seeds').then(() => {
      this.setState({
        isReseedingOptionalSeeds: false,
        showAlert: true,
        alertMsg: 'Successfully Completed Full Suite Seed Job.',
      });
    }, (err) => {
      console.warn(err);
      this.setState({
        isReseedingOptionalSeeds: false,
        showAlert: true,
        alertMsg: err,
      });
    });
  };

  render() {
    const Router = this.props.router || BrowserRouter;
    const appName = 'Case Distribution';
    const tablestyle = {
      display: 'block',
    };

    return (
      <Router {...this.props.routerTestProps}>
        <div>
          <NavigationBar
            wideApp
            defaultUrl={
              this.props.caseSearchHomePage || this.props.hasCaseDetailsRole ?
                '/search' :
                '/queue'
            }
            userDisplayName={this.props.userDisplayName}
            dropdownUrls={this.props.dropdownUrls}
            applicationUrls={this.props.applicationUrls}
            logoProps={{
              overlapColor: LOGO_COLORS.QUEUE.OVERLAP,
              accentColor: LOGO_COLORS.QUEUE.ACCENT,
            }}
            rightNavElement={<CaseSearchLink />}
            appName="Caseflow Admin"
          >
            <AppFrame>
              <AppSegment filledBackground>
                <div>
                  <PageRoute
                    exact
                    path="/acd-controls/test"
                    title="Case Distribution | Caseflow"
                    component={() => {
                      return (
                        <div>
                          <h1 id="top">{COPY.TEST_CASE_DISTRIBUTION_LEVERS_DASHBOARD_TITLE}</h1>
                          <p>{COPY.TEST_CASE_DISTRIBUTION_LEVERS_DESCRIPTION}</p>
                          <h2>{COPY.TEST_NAVIGATION_H2}</h2>
                          <ul>
                            <li>
                              <a href="#levers">
                                {COPY.TEST_CASE_DISTRIBUTION_LEVERS_BUTTON}
                              </a>
                            </li>
                            <li>
                              <a href="#audit">
                                {COPY.TEST_CASE_DISTRIBUTION_AUDIT_LEVERS_BUTTON}
                              </a>
                            </li>
                            <li>
                              <a href="#access_csvs">
                                {COPY.TEST_ACCESS_CSVS_BUTTON}
                              </a>
                            </li>
                            <li>
                              <a href="#run_seeds">
                                {COPY.TEST_CREATE_SEEDED_APPEALS_TITLE}
                              </a>
                            </li>
                            <li>
                              <a href="#case_movement">
                                {COPY.TEST_CASE_MOVEMENT_BUTTON}
                              </a>
                            </li>
                            <li>
                              <a href="#log_of_most_recent_appeals">
                                {COPY.LOG_OF_MOST_RECENT_APPEALS_BUTTON}
                              </a>
                            </li>
                          </ul>
                          <h2 id="levers">{COPY.TEST_CASE_DISTRIBUTION_LEVERS_H2}</h2>
                          <table
                            id="case-table-description"
                            className="usa-table-borderless undefined"
                            style={tablestyle}
                          >
                            <thead>
                              <tr>
                                <td> {COPY.TEST_ID_TD} </td>
                                <td> {COPY.TEST_TITLE_TD} </td>
                                <td> {COPY.TEST_ITEM_TD} </td>
                                <td> {COPY.TEST_CONTROL_GROUP_TD} </td>
                                <td> {COPY.TEST_LEVER_GROUP_TD} </td>
                                <td> {COPY.TEST_LEVER_GROUP_ORDER_TD} </td>
                                <td> {COPY.TEST_DESCRIPTION_TD} </td>
                                <td> {COPY.TEST_DATA_TYPE_TD} </td>
                                <td> {COPY.TEST_VALUE_TD} </td>
                                <td> {COPY.TEST_MIN_MAX_VALUE_TD} </td>
                                <td> {COPY.TEST_UNIT_TD} </td>
                                <td> {COPY.TEST_OPTION_VALUES_TD} </td>
                                <td> {COPY.TEST_TOGGLE_ACTIVE_TD} </td>
                                <td> {COPY.TEST_DISABLED_IN_UI_TD} </td>
                                <td> {COPY.TEST_ALGORITHMS_USED_TD} </td>
                                <td> {COPY.TEST_CREATED_AT_TD} </td>
                                <td> {COPY.TEST_UPDATED_AT_TD} </td>
                              </tr>
                            </thead>
                            <tbody>
                              {this.props.acdLevers.map((lever) => {
                                return [
                                  <tr>
                                    <td> { lever.id } </td>
                                    <td> { lever.title } </td>
                                    <td> { lever.item } </td>
                                    <td> { lever.control_group} </td>
                                    <td> { lever.lever_group } </td>
                                    <td> { lever.lever_group_order } </td>
                                    <td> { lever.description } </td>
                                    <td> { lever.data_type } </td>
                                    <td> { lever.value } </td>
                                    <td> { lever.min_value }/{lever.max_value } </td>
                                    <td> { lever.unit } </td>
                                    <td> { lever.options?.map((option) => option.value).join(', ') } </td>
                                    <td> { lever.is_toggle_active?.toString() } </td>
                                    <td> { lever.is_disabled_in_ui?.toString() } </td>
                                    <td> { lever.algorithms_used } </td>
                                    <td> { lever.created_at } </td>
                                    <td> { lever.updated_at } </td>
                                  </tr>
                                ];
                              })}
                            </tbody>
                          </table>
                          <hr />
                          <h2 id="audit"> {COPY.TEST_CASE_DISTRIBUTION_AUDIT_LEVERS_BUTTON} </h2>
                          <table>
                            <thead>
                              <tr>
                                <td> {COPY.TEST_ID_TD} </td>
                                <td> {COPY.TEST_LEVER_ID_TD} </td>
                                <td> {COPY.TEST_CREATED_AT_TD} </td>
                                <td> {COPY.TEST_PREVIOUS_VALUE_TD} </td>
                                <td> {COPY.TEST_UPDATE_VALUE_TD} </td>
                                <td> {COPY.TEST_USER_CSS_ID_TD} </td>
                                <td> {COPY.TEST_USER_NAME_TD} </td>
                                <td> {COPY.TEST_LEVER_TITLE_TD} </td>
                                <td> {COPY.TEST_LEVER_DATA_TYPE_TD} </td>
                                <td> {COPY.TEST_LEVER_UNIT_TD} </td>
                              </tr>
                            </thead>
                            <tbody>
                              {this.props.acdHistory.map((entry) => {
                                return [
                                  <tr>
                                    <td> { entry.id } </td>
                                    <td> { entry.case_distribution_lever_id } </td>
                                    <td> { entry.created_at } </td>
                                    <td> { entry.previous_value } </td>
                                    <td> { entry.update_value } </td>
                                    <td> { entry.user_css_id } </td>
                                    <td> { entry.user_name } </td>
                                    <td> { entry.lever_title } </td>
                                    <td> { entry.lever_data_type } </td>
                                    <td> { entry.lever_unit } </td>
                                  </tr>
                                ];
                              })}

                            </tbody>
                          </table>
                          <hr />
                          <div className="lever-content">
                            <div className="lever-head csv-download-alignment">
                              <h2 id="access_csvs">{COPY.TEST_ACCESS_CSVS_BUTTON}</h2>
                            </div>
                            <div className="lever-left csv-download-left">
                              <a href="/case_distribution_levers_tests/appeals_ready_to_distribute?csv=1">
                                <Button classNames={['usa-button-active']}>
                                  {COPY.TEST_DOWNLOAD_APPEALS_READY_BUTTON}
                                </Button>
                              </a>
                            </div>
                            <div className="lever-right csv-download-right">
                              <strong>
                                {COPY.TEST_DOWNLOAD_APPEALS_READY_BUTTON}
                              </strong>
                              {COPY.TEST_DOWNLOAD_APPEALS_READY_BUTTON_DESCRIPTION}
                            </div>
                            <div className="lever-left csv-download-left">
                              <a href="/case_distribution_levers_tests/appeals_non_priority_ready_to_distribute?csv=1">
                                <Button classNames={['usa-button-active']}>
                                  {COPY.TEST_DOWNLOAD_AMA_NON_PRIO_DISTR_BUTTON}
                                </Button>
                              </a>
                            </div>
                            <div className="lever-right csv-download-right">
                              <strong>
                                {COPY.TEST_DOWNLOAD_AMA_NON_PRIO_DISTR_BUTTON}
                              </strong>
                              {COPY.TEST_DOWNLOAD_AMA_NON_PRIO_DISTR_BUTTON_DESCRIPTION}
                            </div>
                            <div className="lever-left csv-download-left">
                              <a href="/case_distribution_levers_tests/appeals_tied_to_non_ssc_avlj?csv=1">
                                <Button classNames={['usa-button-active']}>
                                  {COPY.TEST_DOWNLOAD_APPEALS_TIED_NONSSC_AVLJS_BUTTON}
                                </Button>
                              </a>
                            </div>
                            <div className="lever-right csv-download-right">
                              <strong>
                                {COPY.TEST_DOWNLOAD_APPEALS_TIED_NONSSC_AVLJS_BUTTON}
                              </strong>
                              {COPY.TEST_DOWNLOAD_APPEALS_TIED_NONSSC_AVLJS_BUTTON_DESCRIPTION}
                            </div>
                            <div className="lever-left csv-download-left">
                              <a href="/case_distribution_levers_tests/ineligible_judge_list?csv=1">
                                <Button classNames={['usa-button-active']}>
                                  {COPY.TEST_DOWNLOAD_INELIGIBLE_JUDGE_BUTTON}
                                </Button>
                              </a>
                            </div>
                            <div className="lever-right csv-download-right">
                              <strong>
                                {COPY.TEST_DOWNLOAD_INELIGIBLE_JUDGE_BUTTON}
                              </strong>
                              {COPY.TEST_DOWNLOAD_INELIGIBLE_JUDGE_BUTTON_DESCRIPTION}
                            </div>
                            <div className="lever-left csv-download-left">
                              <a href="/case_distribution_levers_tests/appeals_distributed?csv=1">
                                <Button classNames={['usa-button-active']}>
                                  {COPY.TEST_DOWNLOAD_DISTRIBUTED_APPEALS_BUTTON}
                                </Button>
                              </a>
                            </div>
                            <div className="lever-right csv-download-right">
                              <strong>
                                {COPY.TEST_DOWNLOAD_DISTRIBUTED_APPEALS_BUTTON}
                              </strong>
                              {COPY.TEST_DOWNLOAD_DISTRIBUTED_APPEALS_BUTTON_DESCRIPTION}
                            </div>
                            <div className="lever-left csv-download-left">
                              <a href="/case_distribution_levers_tests/appeals_in_location_63_in_past_2_days?csv=1">
                                <Button classNames={['usa-button-active']}>
                                  {COPY.TEST_DOWNLOAD_LOC_63_APPEALS_BUTTON}
                                </Button>
                              </a>
                            </div>
                            <div className="lever-right csv-download-right">
                              <strong>
                                {COPY.TEST_DOWNLOAD_LOC_63_APPEALS_BUTTON}
                              </strong>
                              {COPY.TEST_DOWNLOAD_LOC_63_APPEALS_BUTTON_DESCRIPTION}
                            </div>
                            <div className="lever-left csv-download-left">
                              <a href="/case_distribution_levers_tests/appeals_tied_to_avljs_and_vljs?csv=1">
                                <Button classNames={['usa-button-active']}>
                                  {COPY.TEST_DOWNLOAD_APPEALS_TIED_AVLJ_VLJ_BUTTON}
                                </Button>
                              </a>
                            </div>
                            <div className="lever-right csv-download-right">
                              <strong>
                                {COPY.TEST_DOWNLOAD_APPEALS_TIED_AVLJ_VLJ_BUTTON}
                              </strong>
                              {COPY.TEST_DOWNLOAD_APPEALS_TIED_AVLJ_VLJ_BUTTON_DESCRIPTION}
                            </div>
                          </div>
                          <hr />
                          <h2 id="run_seeds">{COPY.TEST_CREATE_SEEDED_APPEALS_TITLE}</h2>
                          { this.state.showAlert &&
                            <Alert type={this.state.alertType} scrollOnAlert={false}>{this.state.alertMsg}</Alert>
                          }
                          <div className="lever-left csv-download-left">
                            <ResetButton
                              onClick={this.resetAllAppeals}
                              loading={this.state.isClearingAppeals}
                            />
                          </div>
                          <div className="lever-right csv-download-right">
                            <strong>{COPY.TEST_CLEAR_READY_TO_DISTRIBUTE_APPEALS_TITLE}</strong>
                            {COPY.TEST_CLEAR_READY_TO_DISTRIBUTE_APPEALS_DESCRIPTION}
                          </div>
                          <div>
                            <table
                              id="case-table-description"
                              className="usa-table"
                              style={tablestyle}
                            >
                              <thead>
                                <td><p>{COPY.TEST_WARNING_P1}</p>
                                  <p>{COPY.TEST_WARNING_P2}</p>
                                  <p>{COPY.TEST_WARNING_P3}</p>
                                </td>
                              </thead>
                            </table>
                            <div className="lever-left csv-download-left">
                              <Button
                                onClick={this.reseedAod}
                                name="Run Demo AOD Hearing Held Seeds"
                                loading={this.state.isReseedingAod}
                                loadingText="Reseeding AOD Hearing Held Seeds"
                              />
                            </div>
                            <div className="lever-right csv-download-right">
                              <strong>{COPY.TEST_RUN_DEMO_AOD_HEARING_HELD_TITLE}</strong>
                              {COPY.TEST_RUN_DEMO_AOD_HEARING_HELD_DESCRIPTION}
                            </div>
                            <div className="lever-left csv-download-left">
                              <Button
                                onClick={this.reseedNonAod}
                                name="Run Demo Non-AOD Hearing Held Seeds"
                                loading={this.state.isReseedingNonAod}
                                loadingText="Reseeding NON AOD Hearing Held Seeds"
                              />
                            </div>
                            <div className="lever-right csv-download-right">
                              <strong>{COPY.TEST_RUN_DEMO_NON_AOD_HEARING_HELD_TITLE}</strong>
                              {COPY.TEST_RUN_DEMO_NON_AOD_HEARING_HELD_DESCRIPTION}
                            </div>
                            <div className="lever-left csv-download-left">
                              <Button
                                onClick={this.reseedAmaDocketGoals}
                                name="Run Docket Time Goal (AMA non-pri) Seeds"
                                loading={this.state.isReseedingAmaDocketGoals}
                                loadingText="Reseeding Docket Time Goal (AMA non-pri) Seeds"
                              />
                            </div>
                            <div className="lever-right csv-download-right">
                              <strong>{COPY.TEST_RUN_DOCKET_TIME_GOAL_TITLE}</strong>
                              {COPY.TEST_RUN_DOCKET_TIME_GOAL_DESCRIPTION}
                            </div>
                            <div className="lever-left csv-download-left">
                              <Button
                                onClick={this.reseedDocketPriority}
                                name="Run Docket-type Seeds"
                                loading={this.state.isReseedingDocketPriority}
                                loadingText="Reseeding Docket-type Seeds"
                              />
                            </div>
                            <div className="lever-right csv-download-right">
                              <strong>{COPY.TEST_RUN_DOCKET_TYPE_SEEDS_TITLE}</strong>
                              {COPY.TEST_RUN_DOCKET_TYPE_SEEDS_DESCRIPTION}
                            </div>
                            <div className="lever-left csv-download-left">
                              <Button
                                onClick={this.reseedNonSSCAVLJAppeals}
                                name="Run non-SSC AVLJ and Appeal Seeds"
                                loading={this.state.isReseedingNonSSCAVLJAppeals}
                                loadingText="Reseeding non-SSC AVLJ and Appeal Seeds"
                              />
                            </div>
                            <div className="lever-right csv-download-right">
                              <strong>{COPY.TEST_RUN_NONSSC_AVLJ_APPEAL_TITLE}</strong>
                              {COPY.TEST_RUN_NONSSC_AVLJ_APPEAL_DESCRIPTION}
                            </div>
                            <div className="lever-left csv-download-left">
                              <Button
                                onClick={this.reseedGenericFullSuiteAppealsSeeds}
                                name="Run Generic Full Suite Appeals Seeds"
                                loading={this.state.isReseedingOptionalSeeds}
                                loadingText="Reseeding Generic Full Suite Appeals Seeds"
                              />
                            </div>
                            <div className="lever-right csv-download-right">
                              <strong>{COPY.TEST_RUN_GENERIC_FULL_SUITE_APPEALS_TITLE}</strong>
                              {COPY.TEST_RUN_GENERIC_FULL_SUITE_APPEALS_DESCRIPTION}
                            </div>
                          </div>
                          <hr />
                          <div className="lever-content">
                            <div className="lever-head csv-download-alignment">
                              <h2 id="case_movement">{COPY.TEST_CASE_MOVEMENT_TITLE}</h2>
                              { this.state.showLegacyAppealsAlert &&
                              <Alert type={this.state.legacyAppealsAlertType} scrollOnAlert={false}>
                                {this.state.legacyAppealsAlertMsg}
                              </Alert>
                              }
                            </div>
                            <div className="lever-left csv-download-left">
                              <Button classNames={['usa-button-case-movement']}
                                onClick={this.returnLegacyAppealsToBoard}
                                name="Run ReturnLegacyAppealsToBoard job"
                                loading={this.state.isReturnLegacyAppeals}
                                loadingText="Processing ReturnLegacyAppealsToBoard job"
                              />
                            </div>
                            <div className="lever-right csv-download-right">
                              <strong>
                                {COPY.TEST_RETURN_LEGACY_APPEALS_TO_BOARD_JOB_TITLE}
                              </strong>
                              {COPY.TEST_RETURN_LEGACY_APPEALS_TO_BOARD_JOB_DESCRIPTION}
                            </div>
                          </div>
                          <hr />
                          <h2 id="log_of_most_recent_appeals">
                            {COPY.TEST_LOG_OF_MOST_RECENT_APPEALS_MOVED_TITLE}
                          </h2>
                          <CollapsibleTable returnedAppealJobs={this.props.returnedAppealJobs} />
                          <hr />
                          <a href="#top">
                            <button className="btn btn-primary">
                              {COPY.TEST_BACK_TO_TOP_BUTTON}
                            </button>
                          </a>
                        </div>

                      );
                    }}
                  />
                </div>
              </AppSegment>
            </AppFrame>
          </NavigationBar>
          <Footer
            appName={appName}
            feedbackUrl={this.props.feedbackUrl}
            buildDate={this.props.buildDate}
          />
        </div>
      </Router>

    );

  }
}

export default CaseDistributionTest;
