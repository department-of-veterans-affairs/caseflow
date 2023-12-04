import React, { useSelector } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import TextareaField from '../../../components/TextareaField';
import Table from '../../../components/Table';
import { connect } from 'react-redux';

const PackageActionModal = (props) => {
  const rows = [
    {
      correspondence: props.correspondence,
      packageDocumentType: props.packageDocumentType,
      veteranInformation: props.veteranInformation
    },
  ];

  const columns = [
    {
      cellClass: 'cm-packet-number-column',
      header: (
        <span id="cm-packet-number-label">
          CM Packet Number
        </span>
      ),
      valueFunction: () => (
        <span className="cm-packet-number-item">
          <p>{props.correspondence.cmp_packet_number}</p>
        </span>
      )
    },
    {
      cellClass: 'package-document-type-column',
      header: (
        <span id="package-document-type-label">
          Package Document Type
        </span>
      ),
      valueFunction: () => (
        <span className="cm-packet-number-item">
          <p>{props.packageDocumentType.name}</p>
        </span>
      )
    },
    {
      cellClass: 'veteran-details-column',
      header: (
        <span id="veteran-details-label">
          Veteran Details
        </span>
      ),
      valueFunction: () => (
        <span className="cm-packet-number-item">
          <p>
            {`${props.veteranInformation.veteran_name.first_name} ${props.veteranInformation.veteran_name.last_name}
            (${props.veteranInformation.file_number})`}
          </p>
        </span>
      )
    }
  ];

  return (
    <Modal
      title="Request package removal"
      buttons={[
        {
          classNames: ['cf-modal-link', 'cf-btn-link'],
          name: 'Close',
          // onClick: props.handleCancel
        },
        {
          classNames: ['usa-button'],
          name: 'Confirm request',
          // onClick: props.handleSubmit,
        }
      ]}
    >
      <span className="usa-input" style={{ marginBottom: '5px' }}>
        By confirming, you will send a request for the supervisor to take action on the following package:
      </span>
      <Table
        columns={columns}
        rowObjects={rows}
        summary="hello"
      />
      <TextareaField label="Provide a reason for removal" />
    </Modal>
  );
};

PackageActionModal.propTypes = {
  correspondence: PropTypes.object,
  packageDocumentType: PropTypes.object,
  veteranInformation: PropTypes.object
};

const mapStateToProps = (state) => ({
  correspondence: state.reviewPackage.correspondence,
  packageDocumentType: state.reviewPackage.packageDocumentType,
  veteranInformation: state.reviewPackage.veteranInformation
});

export default connect(
  mapStateToProps,
  null,
)(PackageActionModal);
