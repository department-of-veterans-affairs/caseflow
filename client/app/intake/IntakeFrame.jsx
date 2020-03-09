/* eslint-disable react/prop-types */

import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import NavigationBar from '../components/NavigationBar';
import CaseSearchLink from '../components/CaseSearchLink';
import InboxLink from '../components/InboxLink';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { BrowserRouter, Route } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import IntakeProgressBar from './components/IntakeProgressBar';
import CancelIntakeModal from './components/CancelIntakeModal';
import Alert from '../components/Alert';
import SelectFormPage, { SelectFormButton } from './pages/selectForm';
import SearchPage from './pages/search';
import ReviewPage, { ReviewButtons } from './pages/review';
import FinishPage, { FinishButtons } from './pages/finish';
import { IntakeAddIssuesPage } from './pages/addIssues';
import CompletedPage, { CompletedNextButton } from './pages/completed';
import { PAGE_PATHS, REQUEST_STATE } from './constants';
import { toggleCancelModal, submitCancel } from './actions/intake';
import { LOGO_COLORS } from '../constants/AppConstants';
import { css } from 'glamor';

const textAlignRightStyling = css({
  textAlign: 'right'
});

class IntakeFrame extends React.PureComponent {

  render() {
    const appName = 'Intake';

    const Router = this.props.router || BrowserRouter;

    const topMessage = this.props.veteran.fileNumber ?
      `${this.props.veteran.formName} (${this.props.veteran.fileNumber})` : null;

    let rightNavElements = <CaseSearchLink newWindow />;

    if (this.props.featureToggles.inbox) {
      rightNavElements = <span>
        <InboxLink youveGotMail={this.props.unreadMessages} /><CaseSearchLink newWindow />
      </span>;
    }

    return <Router basename="/intake" {...this.props.routerTestProps}>
      <div>
        { this.props.cancelModalVisible && <CancelIntakeModal
          intakeId={this.props.intakeId}
          closeHandler={this.props.toggleCancelModal} />
        }
        <NavigationBar
          appName={appName}
          logoProps={{
            accentColor: LOGO_COLORS.INTAKE.ACCENT,
            overlapColor: LOGO_COLORS.INTAKE.OVERLAP
          }}
          rightNavElement={rightNavElements}
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
          topMessage={topMessage}
          defaultUrl="/">
          <AppFrame>
            <IntakeProgressBar />
            <AppSegment filledBackground>
              { this.props.cancelIntakeRequestStatus === REQUEST_STATE.FAILED &&
                <Alert
                  type="error"
                  title="Error"
                  message={
                    'There was an error while canceling the current intake.' +
                    ' Please try again later.'
                  }
                />
              }
              <div>
                <PageRoute
                  exact
                  path={PAGE_PATHS.BEGIN}
                  title="Select Form | Caseflow Intake"
                  render={() => <SelectFormPage {...this.props} />} />
                <PageRoute
                  exact
                  path={PAGE_PATHS.SEARCH}
                  title="Search | Caseflow Intake"
                  component={SearchPage} />
                <PageRoute
                  exact
                  path={PAGE_PATHS.REVIEW}
                  title="Review Request | Caseflow Intake"
                  render={() => <ReviewPage featureToggles={this.props.featureToggles} />} />
                <PageRoute
                  exact
                  path={PAGE_PATHS.ADD_ISSUES}
                  title="Add / Remove Issues | Caseflow Intake"
                  render={() => <IntakeAddIssuesPage featureToggles={this.props.featureToggles} />} />
                <PageRoute
                  exact
                  path={PAGE_PATHS.FINISH}
                  title="Finish Processing | Caseflow Intake"
                  component={FinishPage} />
                <PageRoute
                  exact
                  path={PAGE_PATHS.COMPLETED}
                  title="Confirmation | Caseflow Intake"
                  component={CompletedPage} />
              </div>
            </AppSegment>
            <AppSegment styling={textAlignRightStyling}>
              <Route
                exact
                path={PAGE_PATHS.BEGIN}
                render={() => <SelectFormButton {...this.props} />} />
              <Route
                exact
                path={PAGE_PATHS.REVIEW}
                component={ReviewButtons} />
              {[PAGE_PATHS.FINISH, PAGE_PATHS.ADD_ISSUES].map((path) =>
                <Route key={path}
                  exact
                  path={path}
                  component={FinishButtons} />
              )}
              <Route
                exact
                path={PAGE_PATHS.COMPLETED}
                component={CompletedNextButton} />
            </AppSegment>
          </AppFrame>
        </NavigationBar>
        <Footer
          appName={appName}
          feedbackUrl={this.props.feedbackUrl}
          buildDate={this.props.buildDate}
        />
      </div>
    </Router>;
  }
}

export default connect(
  ({ intake }) => ({
    intakeId: intake.id,
    unreadMessages: intake.unreadMessages,
    veteran: intake.veteran,
    cancelModalVisible: intake.cancelModalVisible,
    cancelIntakeRequestStatus: intake.requestStatus.cancel
  }),
  (dispatch) => bindActionCreators({
    toggleCancelModal,
    submitCancel
  }, dispatch)
)(IntakeFrame);
