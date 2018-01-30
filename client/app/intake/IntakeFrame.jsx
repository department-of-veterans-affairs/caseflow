import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { BrowserRouter, Route } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import IntakeProgressBar from './components/IntakeProgressBar';
import Modal from '../components/Modal';
import Alert from '../components/Alert';
import Button from '../components/Button';
import SelectFormPage, { SelectFormButton } from './pages/selectForm';
import SearchPage from './pages/search';
import ReviewPage, { ReviewButtons } from './pages/review';
import FinishPage, { FinishButtons } from './pages/finish';
import CompletedPage, { CompletedNextButton } from './pages/completed';
import { PAGE_PATHS, REQUEST_STATE } from './constants';
import { toggleCancelModal, submitCancel } from './actions/common';
import { LOGO_COLORS } from '../constants/AppConstants';
import { css } from 'glamor';

const textAlignRightStyling = css({
  textAlign: 'right'
});

class IntakeFrame extends React.PureComponent {
  handleSubmitCancel = () => (
    this.props.submitCancel(this.props.intakeId)
  )

  render() {
    const appName = 'Intake';

    const Router = this.props.router || BrowserRouter;

    const topMessage = this.props.veteran.fileNumber ?
      `${this.props.veteran.formName} (${this.props.veteran.fileNumber})` : null;

    let cancelButton, confirmButton;

    if (this.props.cancelModalVisible) {
      confirmButton = <Button dangerStyling onClick={this.handleSubmitCancel}>Cancel Intake</Button>;
      cancelButton = <Button linkStyling onClick={this.props.toggleCancelModal} id="close-modal">Close</Button>;
    }

    return <Router basename="/intake" {...this.props.routerTestProps}>
      <div>
        { this.props.cancelModalVisible &&
          <Modal
            title="Cancel Intake?"
            closeHandler={this.props.toggleCancelModal}
            confirmButton={confirmButton}
            cancelButton={cancelButton}
          >
            <p>
              If you have taken any action on this intake outside Caseflow, such as establishing an EP in VBMS,
              Caseflow will have no record of this work.
            </p>
          </Modal>
        }
        <NavigationBar
          appName={appName}
          logoProps={{
            accentColor: LOGO_COLORS.INTAKE.ACCENT,
            overlapColor: LOGO_COLORS.INTAKE.OVERLAP
          }}
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
                  lowerMargin
                />
              }
              <div>
                <PageRoute
                  exact
                  path={PAGE_PATHS.BEGIN}
                  title="Select Form | Caseflow Intake"
                  component={SelectFormPage} />
                <PageRoute
                  exact
                  path={PAGE_PATHS.SEARCH}
                  title="Search | Caseflow Intake"
                  component={SearchPage} />
                <PageRoute
                  exact
                  path={PAGE_PATHS.REVIEW}
                  title="Review Request | Caseflow Intake"
                  component={ReviewPage} />
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
                component={SelectFormButton} />
              <Route
                exact
                path={PAGE_PATHS.REVIEW}
                component={ReviewButtons} />
              <Route
                exact
                path={PAGE_PATHS.FINISH}
                component={FinishButtons} />
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
    veteran: intake.veteran,
    cancelModalVisible: intake.cancelModalVisible,
    cancelIntakeRequestStatus: intake.requestStatus.cancel
  }),
  (dispatch) => bindActionCreators({
    toggleCancelModal,
    submitCancel
  }, dispatch)
)(IntakeFrame);
