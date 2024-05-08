/* eslint-disable no-nested-ternary */
/* eslint-disable max-len */
import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import Button from 'app/components/Button';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import ToggleSwitch from '../../../components/ToggleSwitch/ToggleSwitch';
import { PencilIcon } from '../../../components/icons/PencilIcon';

const buttonStyle = css({
  padding: '1rem 2.5rem 2rem 0',
  display: 'inline-block'
});

const contractorButtonStyle = css({
  paddingLeft: '41rem'
})

const headerContainerStyling = css({
  margin: '1.5rem 0 3rem 0',
  padding: '0 0 0 0',
  '& > *': {
    display: 'inline-block',
    paddingRight: '15px',
    // paddingLeft: '15px',
    verticalAlign: 'middle',
    margin: 0
  }
});

const headerStyling = css({
  paddingLeft: 0,
});

const instructionListStyle = css({
  listStyle: 'none',
  margin: '0 0 0 0',
  padding: '1.5rem 0 2rem 0',
  fontSize: '19px',
});

const returnLinkStyle = css({
  padding: '1.5rem 0 2rem 0rem'
})

const toggleStyle = css({
  padding: '1.5rem 0 2rem 25rem'
})

const userListItemStyle = css({
  display: 'flex',
  flexWrap: 'wrap',
  borderTop: '.1rem solid #d6d7d9',
  padding: '4rem 0 2rem',
  margin: '0'
});

const EditContractorLink = () => (
  <Button
    linkStyling
    // open modal onClick
  >
    {/* <span {...css({ position: 'absolute' })}><PencilIcon size={25} /></span> */}
    <span {...css({ marginRight: '1px', marginLeft: '5px' })} >
      Edit Information
    </span>
    <span {...css({ position: 'absolute' })}><PencilIcon size={25} /></span>
  </Button>
);

const EditHearingsSentLink = () => (
  <Button
    linkStyling
    // open modal onClick
  >
    <span {...css({ marginRight: '1px', marginLeft: '5px' })} >
      Edit Total
    </span>
    <span {...css({ position: 'absolute' })}><PencilIcon size={25} /></span>
  </Button>
);

export default class TranscriptionSettings extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      loading: true
    };
  }

  addContractorButton = () =>
    <div {...buttonStyle}><Button
      name={`Add Contractor`}
      id={`Add-contractor`}
      classNames={['usa-button-primary']}
      // on click add contractor modal opens
      /></div>

  removeContractorButton = () =>
    <div {...buttonStyle}><Button
      name={`Remove Contractor`}
      id={`Remove-contractor`}
      classNames={['usa-button-secondary']}
      // on click contractor is removed
      /></div>

  mainContent = () => {
    const listOfContractors = () => {
      // pass in and iterate over contractors

      return (
        <React.Fragment>
          <div {...userListItemStyle}>
            <div>
              <ul {...instructionListStyle}>
              <h2>{`Contractor A`}<EditContractorLink /></h2>
              <li><strong>{`Link to box.com: `}</strong>{`https://box.com/`}</li>
              <li><strong>{`POC: `}</strong>{`Address here`}</li>
              <span>
                <li><strong>{`Hearings sent to Contractor A this week: `}</strong>{`50 of 160`}<EditHearingsSentLink /></li>
              </span>
              </ul>
            </div>
            <span {...toggleStyle}>
              <h3>{`Temporarily stop work assignment`}</h3>
              <ToggleSwitch />
            </span>
          </div>
          <div {...userListItemStyle}>
            <div>
              <ul {...instructionListStyle}>
                <h2>{`Contractor B`}<EditContractorLink /></h2>
                <li><strong>{`Link to box.com: `}</strong>{`https://box.com/`}</li>
                <li><strong>{`POC: `}</strong>{`Address here`}</li>
                <span>
                  <li><strong>{`Hearings sent to Contractor A this week: `}</strong>{`50 of 160`}<EditHearingsSentLink /></li>
                </span>
              </ul>
            </div>
            <span {...toggleStyle}>
              <h3>{`Temporarily stop work assignment`}</h3>
              <ToggleSwitch />
            </span>
          </div>
        </React.Fragment>
      );
    }

    return (
      <React.Fragment>
        <div>
          <h1 className="cf-margin-bottom-0" {...headerStyling}>
            {`Transcription Settings`}
          </h1>
          <div {...headerContainerStyling}>
            <h2 {...headerStyling}>
              {`Edit Current Contractors`}
            </h2>
            <span {...contractorButtonStyle}>
              {this.removeContractorButton()}
              {this.addContractorButton()}
            </span>
          </div>
        </div>
        <div>
          {listOfContractors()}
        </div>
      </React.Fragment>
    );
  }

  render = () =>
    <AppSegment filledBackground>
      <div {...returnLinkStyle}>
        <span><Link linkStyling>&lt; Back to transcription queue</Link>&nbsp;</span>
      </div>
      <div>
        {this.mainContent()}
      </div>
    </AppSegment>;
}

TranscriptionSettings.propTypes = {

};
