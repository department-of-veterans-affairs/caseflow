/* eslint-disable no-nested-ternary */
/* eslint-disable max-len */
import React from 'react';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from 'app/components/Button';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import ToggleSwitch from '../../../components/ToggleSwitch/ToggleSwitch';
import { PencilIcon } from '../../../components/icons/PencilIcon';
import Alert from '../../../components/Alert';
import ApiUtil from '../../../util/ApiUtil';
import COPY from '../../../../COPY';
import { RemoveContractorModal } from './RemoveContractorModal';

const buttonStyle = css({
  padding: '1rem 2.5rem 2rem 0',
  display: 'inline-block',
});

const contractorButtonStyle = css({
  paddingLeft: '41.55rem',
});

const headerContainerStyling = css({
  margin: '1.5rem 0 3rem 0',
  padding: '0',
  '& > *': {
    display: 'inline-block',
    paddingRight: '15px',
    // paddingLeft: '15px',
    verticalAlign: 'middle',
    margin: 0,
  },
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
  padding: '1.5rem 0 2rem 0rem',
});

const toggleStyle = css({
  padding: '1.5rem 0 2rem 25rem',
});

const userListItemStyle = css({
  display: 'flex',
  flexWrap: 'wrap',
  borderTop: '.1rem solid #d6d7d9',
  padding: '4rem 0 2rem',
  margin: '0',
});

const EditContractorLink = () => (
  <Button linkStyling>
    <span {...css({ marginRight: '1px', marginLeft: '5px' })}>
      Edit Information
    </span>
    <span {...css({ position: 'absolute' })}>
      <PencilIcon size={25} />
    </span>
  </Button>
);

const EditHearingsSentLink = () => (
  <Button linkStyling>
    <span {...css({ marginRight: '1px', marginLeft: '5px' })}>Edit Total</span>
    <span {...css({ position: 'absolute' })}>
      <PencilIcon size={25} />
    </span>
  </Button>
);

export default class TranscriptionSettings extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      isRemoveModalOpen: false,
      loading: true,
      alert: {
        title: '',
        message: '',
        type: '',
      },
      isAddEditOpen: false,

      contractors: [],
    };
  }

  toggleRemoveModal = () => {
    this.setState((prevState) => ({
      isRemoveModalOpen: !prevState.isRemoveModalOpen,
    }));
  };

  handleRemoveContractor = (contractorId) => {
    return new Promise((resolve, reject) => {
      ApiUtil.delete(`/hearings/find_by_contractor/${contractorId}`).
        then(() => {
          this.setState(
            {
              isRemoveModalOpen: false,
            },
            () => {
              this.getContractors();
              this.confirmRemoveModal({
                title: 'Success',
                message: COPY.TRANSCRIPTION_SETTINGS_CONTRACTOR_REMOVAL_SUCCESS,
                type: 'success',
              });
              resolve();
            }
          );
        }).
        catch((error) => {
          console.error(error);
          this.setState(
            {
              alert: {
                title: 'Error',
                message: COPY.TRANSCRIPTION_SETTINGS_CONTRACTOR_REMOVAL_FAIL,
                type: 'error',
              },
              isRemoveModalOpen: false,
            },
            () => {
              reject(error);
            }
          );
        });
    });
  };

  confirmRemoveModal = (alert) => {
    this.setState({ alert });
    this.toggleRemoveModal();
  };

  getContractors = () => {
    ApiUtil.get('/hearings/find_by_contractor').then((response) => {
      this.setState({
        contractors: response.body.transcription_contractors,
        loading: false,
      });
    });
  };

  componentDidMount() {
    this.getContractors();
  }

  addContractorButton = () => (
    <div {...buttonStyle}>
      <Button
        name={COPY.TRANSCRIPTION_SETTINGS_ADD}
        id="Add-contractor"
        classNames={['usa-button-primary']}
        // on click add contractor modal opens
      />
    </div>
  );

  removeContractorButton = () => (
    <div {...buttonStyle}>
      <Button
        name={COPY.TRANSCRIPTION_SETTINGS_REMOVE}
        id="Remove-contractor"
        classNames={['usa-button-secondary']}
        onClick={() => this.toggleRemoveModal()}
        // on click contractor is removed
      />
    </div>
  );

  mainContent = () => {
    const listOfContractors = () => {
      // pass in and iterate over contractors
      return (
        <React.Fragment>
          <div {...userListItemStyle}>
            <div>
              <ul {...instructionListStyle}>
                <h2>
                  {COPY.TRANSCRIPTION_SETTINGS_CONTRACTOR_NAME}
                  <EditContractorLink />
                </h2>
                <li>
                  <strong>{COPY.TRANSCRIPTION_SETTINGS_BOX_LINK}</strong>
                  `https://box.com/`
                </li>
                <li>
                  <strong>{COPY.TRANSCRIPTION_SETTINGS_POC_ADDRESS}</strong>
                  `Address here`
                </li>
                <span>
                  <li>
                    <strong>{COPY.TRANSCRIPTION_SETTINGS_HEARINGS_SENT}</strong>
                    `50 of 160`
                    <EditHearingsSentLink />
                  </li>
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
    };

    return (
      <React.Fragment>
        <div>
          <h1 className="cf-margin-bottom-0" {...headerStyling}>
            {COPY.TRANSCRIPTION_SETTINGS_HEADER}
          </h1>
          <div {...headerContainerStyling}>
            <h2 {...headerStyling}>{COPY.TRANSCRIPTION_SETTINGS_SUBHEADER}</h2>
            <span {...contractorButtonStyle}>
              {this.removeContractorButton()}
              {this.addContractorButton()}
            </span>
          </div>
        </div>
        <div>{listOfContractors()}</div>
      </React.Fragment>
    );
  };

  render = () => (
    <>
      {this.state.alert.title && (
        <Alert
          title={this.state.alert.title}
          message={this.state.alert.message}
          type={this.state.alert.type}
        />
      )}
      <AppSegment filledBackground>
        <div {...returnLinkStyle}>
          <span>
            <Link linkStyling>&lt; {COPY.TRANSCRIPTION_QUEUE_LINK}</Link>
            &nbsp;
          </span>
        </div>
        <div>{this.mainContent()}</div>
        {this.state.isRemoveModalOpen && (
          <RemoveContractorModal
            onCancel={this.toggleRemoveModal}
            onConfirm={this.handleRemoveContractor}
            contractors={this.state.contractors}
            title={COPY.TRANSCRIPTION_SETTINGS_REMOVE_CONTRACTOR_MODAL_TITLE}
          />
        )}
      </AppSegment>
    </>
  );
}

TranscriptionSettings.propTypes = {
  contractors: PropTypes.array.isRequired,
};
