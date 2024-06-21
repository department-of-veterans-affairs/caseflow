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

class CaseDistributionTest extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      isReseedingAod: false,
      isReseedingNonAod: false,
      isReseedingAmaDocketGoals: false,
      isReseedingDocketPriority: false
    };
  }

  reseedAod = () => {
    this.setState({ isReseedingAod: true });
    ApiUtil.post('/case_distribution_levers_tests/run_demo_aod_hearing_seeds').then(() => {
      this.setState({
        isReseedingAod: false,
      });
    }, (err) => {
      console.warn(err);
      this.setState({
        isReseedingAod: false,
      });
    });
  };

  reseedNonAod = () => {
    this.setState({ isReseedingNonAod: true });
    ApiUtil.post('/case_distribution_levers_tests/run_demo_non_aod_hearing_seeds').then(() => {
      this.setState({
        isReseedingNonAod: false,
      });
    }, (err) => {
      console.warn(err);
      this.setState({
        isReseedingNonAod: false,
      });
    });
  };

  reseedAmaDocketGoals = () => {
    this.setState({ isReseedingAmaDocketGoals: true });
    ApiUtil.post('/case_distribution_levers_tests/run-demo-ama-docket-goals').then(() => {
      this.setState({
        isReseedingAmaDocketGoals: false,
      });
    }, (err) => {
      console.warn(err);
      this.setState({
        isReseedingAmaDocketGoals: false,
      });
    });
  };

  reseedDocketPriority = () => {
    this.setState({ isReseedingDocketPriority: true });
    ApiUtil.post('/case_distribution_levers_tests/run-demo-docket-priority').then(() => {
      this.setState({
        isReseedingDocketPriority: false,
      });
    }, (err) => {
      console.warn(err);
      this.setState({
        isReseedingDocketPriority: false,
      });
    });
  };

  render() {
    const Router = this.props.router || BrowserRouter;
    const appName = 'Case Distribution';
    const tablestyle = {
      display: 'block',
      overflowX: 'scroll'
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
                          <h1 id="top">Case Distribution Levers Dashboard</h1>
                          <p>This page is for lower env use only and provides a convient place to review{' '}
                          Case Distribution related data</p>
                          <h2>Navigation</h2>
                          <ul>
                            <li>
                              <a href="#levers">
                                <button className="btn btn-primary">Case Distribution Levers</button>
                              </a>
                            </li>
                            <li>
                              <a href="#audit">
                                <button className="btn btn-primary">Case Distribution Audit Levers</button>
                              </a>
                            </li>
                            <li>
                              <a href="#distribution_status">
                                <button className="btn btn-primary">Distribution Status</button>
                              </a>
                            </li>
                          </ul>
                          <h2 id="levers"> Case Distribution Levers </h2>
                          <table
                            id="case-table-description"
                            className="usa-table-borderless undefined"
                            style={tablestyle}
                          >
                            <thead>
                              <tr>
                                <td> ID </td>
                                <td> Title </td>
                                <td> Item </td>
                                <td> Control Group </td>
                                <td> Lever Group </td>
                                <td> Lever Group Order </td>
                                <td> Description </td>
                                <td> Data Type </td>
                                <td> Value </td>
                                <td> Min / Max Value </td>
                                <td> Unit </td>
                                <td> Option Values</td>
                                <td> Toggle Active </td>
                                <td> Disabled In UI</td>
                                <td> Algorithms Used </td>
                                <td> Created At </td>
                                <td> Updated At </td>
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
                          <h2 id="audit"> Case Distribution Audit Levers </h2>
                          <table>
                            <thead>
                              <tr>
                                <td> ID </td>
                                <td> Lever ID </td>
                                <td> Created At </td>
                                <td> Previous Value</td>
                                <td> Update Value </td>
                                <td> User CSS ID </td>
                                <td> User Name</td>
                                <td> Lever Title </td>
                                <td> Lever Data Type </td>
                                <td> Lever Unit </td>
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
                          <h2 id="distribution_status">Distribution Status</h2>
                          <ul>
                            <li>
                              <a href="/case_distribution_levers_tests/appeals_ready_to_distribute?csv=1">
                                <Button classNames={['usa-button-active']}>
                                  Download Appeals Ready to Distribute CSV
                                </Button>
                              </a>
                            </li>
                            <li>
                              <a href="/case_distribution_levers_tests/appeals_distributed?csv=1">
                                <Button classNames={['usa-button-active']}>Download Distributed Appeals CSV</Button>
                              </a>
                            </li>
                            <li>
                              <a href="/case_distribution_levers_tests/ineligible_judge_list?csv=1">
                                <Button classNames={['usa-button-active']}>Download Ineligible Judge List</Button>
                              </a>
                            </li>
                            <li>
                              <a href="/case_distribution_levers_tests/appeals_non_priority_ready_to_distribute?csv=1">
                                <Button classNames={['usa-button-active']}>
                                  Download AMA Non-priority Distributable CSV
                                </Button>
                              </a>
                            </li>
                          </ul>
                          <hr />
                          <h2 id="run_seeds">Run Seed Files</h2>
                          <ul>
                            <li>
                              <Button
                                onClick={this.reseedAod}
                                name="Run Demo AOD Hearing Held Seeds"
                                loading={this.state.isReseedingAod}
                                loadingText="Reseeding AOD Hearing Held Seeds"
                              />
                            </li>
                            <li>
                              <Button
                                onClick={this.reseedNonAod}
                                name="Run Demo NON AOD Hearing Held Seeds"
                                loading={this.state.isReseedingNonAod}
                                loadingText="Reseeding NON AOD Hearing Held Seeds"
                              />
                            </li>
                            <li>
                              {/* <a href="/run-demo-ama-docket-goals">
                                <button className="btn btn-primary">Run Demo Ama Docket Goals</button>
                              </a> */}
                              <Button
                                onClick={this.reseedAmaDocketGoals}
                                name="Run Demo Ama Docket Goals"
                                loading={this.state.isReseedingAmaDocketGoals}
                                loadingText="Reseeding Ama Docket Goals"
                              />
                            </li>
                            <li>
                              {/* <a href="/run-demo-docket-priority">
                                <button className="btn btn-primary">Run Demo Docket Priority</button>
                              </a> */}
                              <Button
                                onClick={this.reseedDocketPriority}
                                name="Run Demo Docket Priority"
                                loading={this.state.isReseedingDocketPriority}
                                loadingText="Reseeding Docket Priority"
                              />
                            </li>
                          </ul>
                          <hr />
                          <a href="#top"><button className="btn btn-primary">Back to Top</button></a>
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
