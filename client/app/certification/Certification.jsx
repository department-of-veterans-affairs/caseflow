import React from 'react';
import PropTypes from 'prop-types';
import ReduxBase from '../components/ReduxBase';
import _ from 'lodash';

import CertificationFrame from './CertificationFrame';
import { certificationReducers, mapDataToInitialState } from './reducers/index';
import ApiUtil from '../util/ApiUtil';
import * as AppConstants from '../constants/AppConstants';
import LoadingDataDisplay from '../components/LoadingDataDisplay';

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
          then((response) => {
            if (response.body.loading_data_failed) {
              reject(new Error('Backend failed to load data'));
            }

            if (response.body.loading_data) {
              setTimeout(makePollAttempt, AppConstants.CERTIFICATION_DATA_POLLING_INTERVAL);

              return;
            }

            this.setState(_.pick(response.body, ['certification', 'form9PdfPath']));
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
      loadingComponentProps={{
        message: 'Loading and checking documents from the Veteran’s file…',
        spinnerColor: AppConstants.LOGO_COLORS.CERTIFICATION.ACCENT
      }}
      failStatusMessageProps={{
        title: 'Technical Difficulties'
      }}
      failStatusMessageChildren={failStatusMessageChildren}>
      { this.state.certification &&
        <ReduxBase reducer={certificationReducers} initialState={initialData}>
          <CertificationFrame {...this.props} />
        </ReduxBase> }
    </LoadingDataDisplay>;
  }
}

Certification.propTypes = {
  vacolsId: PropTypes.string
};
