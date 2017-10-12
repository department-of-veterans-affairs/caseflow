import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import NavigationBar from '../components/NavigationBar';
import Footer from '../components/Footer';
import { BrowserRouter, Route } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '../components/AppSegment';
import IntakeProgressBar from './components/IntakeProgressBar';
import PrimaryAppContent from '../components/PrimaryAppContent';
import Modal from '../components/Modal';
import Button from '../components/Button';
import BeginPage from './pages/begin';
import ReviewPage, { ReviewButtons } from './pages/review';
import FinishPage, { FinishButtons } from './pages/finish';
import CompletedPage, { CompletedNextButton } from './pages/completed';
import { PAGE_PATHS, REQUEST_STATE } from './constants';
import { toggleCancelModal } from './redux/actions';

class IntakeFrame extends React.PureComponent {
  render() {
    const appName = 'Intake';

    const Router = this.props.router || BrowserRouter;

    const topMessage = this.props.fileNumberSearchRequestStatus === REQUEST_STATE.SUCCEEDED ?
      `${this.props.veteran.formName} (${this.props.veteran.fileNumber})` : null;

    let cancelButton, confirmButton;

    if (this.props.cancelModalVisible) {
      confirmButton = <Button dangerStyling>Cancel Intake</Button>;
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
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
          topMessage={topMessage}
          defaultUrl="/">
          <AppFrame>
            <IntakeProgressBar />
            <PrimaryAppContent>
              <PageRoute
                exact
                path={PAGE_PATHS.BEGIN}
                title="Begin Intake | Caseflow Intake"
                component={BeginPage} />
              <PageRoute
                exact
                path={PAGE_PATHS.REVIEW}
                title="Review Request | Caseflow Intake"
                component={ReviewPage} />
              <PageRoute
                exact
                path={PAGE_PATHS.FINISH}
                title="Finish | Caseflow Intake"
                component={FinishPage} />
              <PageRoute
                exact
                path={PAGE_PATHS.COMPLETED}
                title="Completed | Caseflow Intake"
                component={CompletedPage} />
            </PrimaryAppContent>
            <AppSegment className="cf-workflow-button-wrapper">
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
  ({ veteran, requestStatus, cancelModalVisible }) => ({
    veteran,
    cancelModalVisible,
    fileNumberSearchRequestStatus: requestStatus.fileNumberSearch
  }),
  (dispatch) => bindActionCreators({
    toggleCancelModal
  }, dispatch)
)(IntakeFrame);
