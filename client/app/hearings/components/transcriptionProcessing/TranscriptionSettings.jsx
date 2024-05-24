/* eslint-disable no-nested-ternary */
/* eslint-disable max-len */
import React from 'react';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import Button from 'app/components/Button';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import ToggleSwitch from '../../../components/ToggleSwitch/ToggleSwitch';
import { PencilIcon } from '../../../components/icons/PencilIcon';

import COPY from '../../../../COPY';

const buttonStyle = css({
  padding: '1rem 2.5rem 2rem 0',
  display: 'inline-block'
});

const contractorButtonStyle = css({
  paddingLeft: '41.55rem'
});

const headerContainerStyling = css({
  margin: '1.5rem 0 3rem 0',
  padding: '0',
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
  margin: '0',
  padding: '1.5rem 0 2rem 0',
  fontSize: '19px',
});

const returnLinkStyle = css({
  padding: '1.5rem 0 2rem 0rem'
});

const toggleStyle = css({
  padding: '1.5rem 0 2rem 25rem'
});

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
      loading: true,
      contractors: props.contractors
    };
  }

  addContractorButton = () =>
    <div {...buttonStyle}><Button
      name={COPY.TRANSCRIPTION_SETTINGS_ADD}
      id="Add-contractor"
      classNames={['usa-button-primary']}
      // on click add contractor modal opens
    /></div>

  removeContractorButton = () =>
    <div {...buttonStyle}><Button
      name={COPY.TRANSCRIPTION_SETTINGS_REMOVE}
      id="Remove-contractor"
      classNames={['usa-button-secondary']}
      // on click contractor is removed
    /></div>

  mainContent = () => {
    const listOfContractors = this.props.contractors.map((contractor) => {

      return (
        <React.Fragment>
          <div {...userListItemStyle}>
            <div>
              <ul {...instructionListStyle}>
                <h2>{contractor.name}<EditContractorLink /></h2>
                <li><strong>{COPY.TRANSCRIPTION_SETTINGS_BOX_LINK}</strong>{contractor.directory}</li>
                <li><strong>{COPY.TRANSCRIPTION_SETTINGS_POC_ADDRESS}</strong>{contractor.poc}</li>
                <li>{contractor.phone}</li>
                <li>{contractor.email}</li>
                <span>
                  <li><strong>{COPY.TRANSCRIPTION_SETTINGS_HEARINGS_SENT}</strong>{`0 of `}{contractor.current_goal}<EditHearingsSentLink /></li>
                </span>
              </ul>
            </div>
            <span {...toggleStyle}>
              <h3>{COPY.TRANSCRIPTION_SETTINGS_WORK_TOGGLE}</h3>
              <ToggleSwitch />
            </span>
          </div>
        </React.Fragment>
      );
    });

    return (
      <React.Fragment>
        <div>
          <h1 className="cf-margin-bottom-0" {...headerStyling}>
            {COPY.TRANSCRIPTION_SETTINGS_HEADER}
          </h1>
          <div {...headerContainerStyling}>
            <h2 {...headerStyling}>
              {COPY.TRANSCRIPTION_SETTINGS_SUBHEADER}
            </h2>
            <span {...contractorButtonStyle}>
              {this.removeContractorButton()}
              {this.addContractorButton()}
            </span>
          </div>
        </div>
        <div>
        { listOfContractors.length > 0 ? (
          <ul>{listOfContractors}</ul>
        ) : (
          <>
            <p className="no-results-found-styling">No contractors found</p>
          </>
        )
        }
      </div>
      </React.Fragment>
    );
  }

  render = () =>
    <AppSegment filledBackground>
      <div {...returnLinkStyle}>
        <span><Link linkStyling>&lt; {COPY.TRANSCRIPTION_QUEUE_LINK}</Link>&nbsp;</span>
      </div>
      <div>
        {this.mainContent()}
      </div>
    </AppSegment>;
}

TranscriptionSettings.propTypes = {

};
