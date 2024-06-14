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
import { AddEditContractorModal } from './AddEditContractorModal';

const buttonStyle = css({
  float: 'left',
  paddingLeft: '2rem'
});

const headerContainerStyling = css({
  padding: '4rem 0 2.5rem',
  '& h2': {
    display: 'inline-block',
    verticalAlign: 'middle',
    paddingTop: '0.5rem',
  }
});

const instructionListStyle = css({
  listStyle: 'none',
  margin: '0',
  padding: '1.5rem 0 2rem 0',
  fontSize: '19px',
});

const contactAlign = css({
  paddingLeft: '4.5rem'
});

const returnLinkStyle = css({
  paddingTop: '3rem',
});

const toggleStyle = css({
  padding: '1.5rem 6rem 2rem 2rem',
});

const userListItemStyle = css({
  display: 'flex',
  flexWrap: 'wrap',
  borderTop: '.1rem solid #d6d7d9',
  padding: '4rem 0 2rem',
  clear: 'both'
});

const editlinkStyle = css({
  display: 'flex',
  flexWrap: 'wrap'
});

const contractorDetailStyle = css({
  flex: '1'
});

const alertStyle = css({
  '& .usa-alert': {
    paddingBottom: '2rem'
  }
});

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
      loading: true,
      contractors: props.contractors,
      isRemoveModalOpen: false,
      isAddEditOpen: false,
      alert: {
        title: '',
        message: '',
        type: '',
      }
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
                title: COPY.TRANSCRIPTION_SETTINGS_CONTRACTOR_REMOVAL_SUCCESS,
                message: '',
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

  addContractorButton = () => (
    <div {...buttonStyle}>
      <Button
        name={COPY.TRANSCRIPTION_SETTINGS_ADD}
        id="Add-contractor"
        classNames={['usa-button-primary']}
        onClick={() => this.toggleAddEditModal()}
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
      />
    </div>
  );

  editContractorLink = (id) => (
    <div>
      <Button linkStyling onClick={() => this.editContractor(id)}>
        <span {...css({ marginRight: '1px', marginLeft: '5px' })}>
          Edit Information
        </span>
        <span {...css({ position: 'absolute' })}>
          <PencilIcon size={25} />
        </span>
      </Button>
    </div>
  );

  confirmEditAddModal = (response) => {
    this.setState({ alert: response.alert });
    this.getContractors();
    this.toggleAddEditModal();
  };

  toggleAddEditModal = () => this.setState({ isAddEditOpen: !this.state.isAddEditOpen });

  editContractor = (id) => {
    const currentContractor = this.state.contractors.find((contractor) => contractor.id === id);

    this.setState({ currentContractor: {
      transcriptionContractor: currentContractor
    } });

    this.toggleAddEditModal();
  };

  addContractor = () => {
    this.setState({ currentContractor: null });
    this.toggleAddEditModal();
  };

  sortedContractors = () => {
    const group = this.state.contractors.sort((aString, bString) => {
      const nameA = aString.name.toUpperCase();
      const nameB = bString.name.toUpperCase();

      if (nameA < nameB) {
        return -1;
      }

      if (nameA > nameB) {
        return 1;
      }

      return 0;
    });

    return group;
  };

  mainContent = () => {
    const listOfContractors = this.sortedContractors().map((contractor) => {
      return (
        <React.Fragment key={contractor.id}>
          <div {...userListItemStyle}>
            <div {...contractorDetailStyle}>
              <ul {...instructionListStyle}>
                <h2 {...editlinkStyle}>
                  {contractor.name}
                  {this.editContractorLink(contractor.id)}
                </h2>
                <li><strong>{COPY.TRANSCRIPTION_SETTINGS_BOX_LINK}</strong>{contractor.directory}</li>
                <li><strong>{COPY.TRANSCRIPTION_SETTINGS_POC_ADDRESS}</strong>{contractor.poc}</li>
                <li {...contactAlign}>{contractor.phone}</li>
                <li {...contactAlign}>{contractor.email}</li>
                <span>
                  <li><strong>{'Hearings sent to '}{contractor.name}{' this week: '}</strong>{'0 of '}{contractor.current_goal}<EditHearingsSentLink /></li>
                </span>
              </ul>
            </div>
            <span {...toggleStyle}>
              <h3>Temporarily stop<br /> work assignment</h3>
              <ToggleSwitch selected={contractor.is_available_for_work} />
            </span>
          </div>
        </React.Fragment>
      );
    });

    return (
      <React.Fragment>
        <div>
          <h1 className="cf-margin-bottom-0">
            {COPY.TRANSCRIPTION_SETTINGS_HEADER}
          </h1>
          <div {...headerContainerStyling}>
            <h2>
              {COPY.TRANSCRIPTION_SETTINGS_SUBHEADER}
            </h2>
            <span className="cf-push-right">
              {this.removeContractorButton()}
              {this.addContractorButton()}
            </span>
          </div>
        </div>
        <div>
          { listOfContractors.length > 0 ? (
            <div>{listOfContractors}</div>
          ) : (
            <>
              <p className="no-results-found-styling">No contractors found</p>
            </>
          )
          }
        </div>
        {this.state.isAddEditOpen && <AddEditContractorModal
          onCancel={this.toggleAddEditModal}
          onConfirm={this.confirmEditAddModal}
          {...this.state.currentContractor}
        />}
        {this.state.isRemoveModalOpen && (
          <RemoveContractorModal
            onCancel={this.toggleRemoveModal}
            onConfirm={this.handleRemoveContractor}
            contractors={this.state.contractors}
            title={COPY.TRANSCRIPTION_SETTINGS_REMOVE_CONTRACTOR_MODAL_TITLE}
          />
        )}
      </React.Fragment>
    );
  };

  render = () => (
    <>
      <div {...returnLinkStyle}>
        <span>
          <Link linkStyling>&lt; {COPY.TRANSCRIPTION_QUEUE_LINK}</Link>
          &nbsp;
        </span>
      </div>
      {this.state.alert.title && (
        <div {...alertStyle}>
          <Alert
            title={this.state.alert.title}
            message={this.state.alert.message}
            type={this.state.alert.type}
          />
        </div>
      )}
      <AppSegment filledBackground>
        <div>{this.mainContent()}</div>
      </AppSegment>
    </>
  );
}

TranscriptionSettings.propTypes = {
  contractors: PropTypes.array.isRequired,
};
