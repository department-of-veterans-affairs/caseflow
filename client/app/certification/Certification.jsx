import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/ReduxBase';

import { BrowserRouter, Route, Redirect } from 'react-router-dom';
import { connect } from 'react-redux';
import _ from 'lodash';

import Success from './Success';
import DocumentsCheck from './DocumentsCheck';
import ConfirmHearing from './ConfirmHearing';
import ConfirmCaseDetails from './ConfirmCaseDetails';
import SignAndCertify from './SignAndCertify';
import CancelCertificationConfirmation from './CancelCertificationConfirmation';
import { certificationReducers, mapDataToInitialState } from './reducers/index';
import ErrorMessage from './ErrorMessage';
import PageRoute from '../components/PageRoute';
import ApiUtil from '../util/ApiUtil';
import * as AppConstants from '../constants/AppConstants';
import { LOGO_COLORS } from '@department-of-veterans-affairs/appeals-frontend-toolkit/util/StyleConstants';
import LoadingDataDisplay from '../components/LoadingDataDisplay';

class EntryPointRedirect extends React.Component {
  render() {
    let {
      match
    } = this.props;

    return <Redirect to={`/certifications/${match.params.vacols_id}/check_documents`} />;
  }
}

const mapStateToProps = (state) => ({
  certificationStatus: state.certificationStatus
});

export default connect(
  mapStateToProps
)(EntryPointRedirect);

export class Certification extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      certification: null,
      form9PdfPath: null
    };
  }

  createLoadPromise = () => {
    const loadPromise = new Promise((resolve, reject) => {
      const makePollAttempt = () => {
        ApiUtil.get(`/certifications/${this.props.vacolsId}`).
          then(({ text }) => {
            const response = JSON.parse(text);

            if (response.loading_data_failed) {
              reject(new Error('Backend failed to load data'));
            }

            if (response.loading_data) {
              setTimeout(makePollAttempt, AppConstants.CERTIFICATION_DATA_POLLING_INTERVAL);

              return;
            }

            this.setState(_.pick(response, ['certification', 'form9PdfPath']));
            resolve();
          }, reject);
      };

      makePollAttempt();
    });

    return loadPromise;
  }

  render() {
    const failStatusMessageChildren = <div>
      Systems that Caseflow Certification connects to are experiencing technical difficulties
      and Caseflow is unable to load.
      We apologize for any inconvenience. Please try again later.
    </div>;

    let initialData;

    if (this.state.certification) {
      initialData = mapDataToInitialState(this.state.certification, this.state.form9PdfPath);
    }

    return <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      slowLoadThresholdMs={AppConstants.LONGER_THAN_USUAL_TIMEOUT}
      timeoutMs={AppConstants.CERTIFICATION_DATA_OVERALL_TIMEOUT}
      slowLoadMessage="Documents are taking longer to load than usual. Thanks for your patience!"
      loadingScreenProps={{
        message: 'Loading and checking documents from the Veteran’s file…',
        spinnerColor: AppConstants.LOADING_INDICATOR_COLOR_CERTIFICATION
      }}
      failStatusMessageProps={{
        title: 'Technical Difficulties'
      }}
      failStatusMessageChildren={failStatusMessageChildren}>
      { this.state.certification &&
        <ReduxBase reducer={certificationReducers} initialState={initialData}>
          <BrowserRouter>
            <div>
              <Route path="/certifications/new/:vacols_id"
                component={EntryPointRedirect} />
              <PageRoute
                title="Check Documents | Caseflow Certification"
                path="/certifications/:vacols_id/check_documents"
                component={DocumentsCheck}
              />
              <PageRoute
                title="Confirm Case Details | Caseflow Certification"
                path="/certifications/:vacols_id/confirm_case_details"
                component={ConfirmCaseDetails}
              />
              <PageRoute
                title="Confirm Hearing | Caseflow Certification"
                path="/certifications/:vacols_id/confirm_hearing"
                component={ConfirmHearing}
              />
              <PageRoute
                title="Sign and Certify | Caseflow Certification"
                path="/certifications/:vacols_id/sign_and_certify"
                component={SignAndCertify} />
              <PageRoute
                title="Success! | Caseflow Certification"
                path="/certifications/:vacols_id/success"
                component={Success}
              />
              <PageRoute
                title="Error | Caseflow Certification"
                path="/certifications/error"
                component={ErrorMessage}
              />
              <PageRoute
                title="Not Certified | Caseflow Certification"
                path="/certification_cancellations/"
                component={CancelCertificationConfirmation}
              />
            </div>
          </BrowserRouter>
        </ReduxBase> }
    </LoadingDataDisplay>;
  }
}
