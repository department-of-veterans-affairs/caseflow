/* eslint-disable no-nested-ternary */
/* eslint-disable max-len */
import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import Button from 'app/components/Button';

const headerContainerStyling = css({
  margin: '-2rem 0 0 0',
  padding: '0 0 1.5rem 0',
  '& > *': {
    display: 'inline-block',
    paddingRight: '15px',
    paddingLeft: '15px',
    verticalAlign: 'middle',
    margin: 0
  }
});

const headerStyling = css({
  paddingLeft: 0,
});

const buttonStyle = css({
  padding: '1rem 2.5rem 2rem 0',
  display: 'inline-block'
});

export default class TranscriptionSettings extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      loading: true
    };
  }

  // addContractorButton = () =>
  //   <div {...buttonStyle}><Button
  //     name={`Add Contractor`}
  //     id={`Add-contractor`}
  //     // classNames={['usa-button-primary']}
  //     // on click add contractor modal opens
  //     /></div>

  // removeContractorButton = () =>
  //   <div {...buttonStyle}><Button
  //     name={`Remove Contractor`}
  //     id={`Remove-contractor`}
  //     // classNames={['usa-button-secondary']}
  //     // on click contractor is removed
  //     /></div>

  mainContent = () => {
    return (
      <React.Fragment>
        <div {...headerContainerStyling}>
          <h1 className="cf-margin-bottom-0" {...headerStyling}>
            {`Transcription Settings`}
          </h1>
          <div {...headerContainerStyling}>
            <h2 {...headerStyling}>
              {`Edit Current Contractors`}
            </h2>
            <span>
              {/* {this.removeContractorButton()}
              {this.addContractorButton()} */}
            </span>
          </div>
        </div>
        <div>
          <h2>{`Contractor A`}</h2>
          <h4>{`Link to box.com: `}</h4>
          <h4>{`POC:`}</h4>
          <h4>{`Hearings sent to Contractor A this week:`}</h4>
        </div>
      </React.Fragment>
    );
  }

  render = () => <LoadingDataDisplay>
  <AppSegment filledBackground>
    <div>
      {this.mainContent()}
    </div>
  </AppSegment>
</LoadingDataDisplay>;
}

TranscriptionSettings.propTypes = {

};
