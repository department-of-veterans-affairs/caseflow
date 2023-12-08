import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import TextareaField from '../../../components/TextareaField';
import Table from '../../../components/Table';
import { connect } from 'react-redux';
import ApiUtil from '../../../util/ApiUtil';
import { getPackageActionColumns, getModalInformation } from '../review_package/utils';
import { useHistory } from 'react-router';

const PackageActionModal = (props) => {
  const {
    packageActionModal,
    correspondence,
    packageDocumentType,
    veteranInformation,
    closeHandler,
  } = props;

  const modalInfo = getModalInformation(packageActionModal);
  const history = useHistory();

  const [textInputReason, setTextInputReason] = useState('');

  const rows = [
    {
      correspondence,
      packageDocumentType,
      veteranInformation
    }
  ];

  // Disable submit button unless conditional input is met
  const disableSubmit = () => {
    switch (packageActionModal) {
    case 'removePackage':
      return textInputReason === '';
    case 'reassignPackage':
      return textInputReason === '';
    default:
      return true;
    }
  };

  const submitHandler = async () => {
    const data = {
      correspondence_id: correspondence.id,
      type: packageActionModal,
      instructions: []
    };

    if (packageActionModal === 'removePackage' || packageActionModal === 'reassignPackage') {
      data.instructions.push(textInputReason);
    }

    ApiUtil.post(`/queue/correspondence/${correspondence.uuid}/task`, { data }).then((response) => {
      props.closeHandler(null);
      if (response.ok) {
        history.push('/queue/correspondence');
      }
    }
    );
  };

  return (
    <Modal
      title={modalInfo.title}
      buttons={[
        {
          classNames: ['cf-modal-link', 'cf-btn-link'],
          name: 'Close',
          onClick: () => closeHandler(null)
        },
        {
          classNames: ['usa-button'],
          name: 'Confirm request',
          disabled: disableSubmit(),
          onClick: submitHandler,
        }
      ]}
      closeHandler={() => props.closeHandler(null)}
    >
      <span className="usa-input" style={{ marginBottom: '5px' }}>
        {modalInfo.description}
      </span>
      <Table
        columns={getPackageActionColumns(packageActionModal)}
        rowObjects={rows}
        slowReRendersAreOk
        summary="Request Package Action Modal"
      />
      {
        (packageActionModal === 'removePackage' || packageActionModal === 'reassignPackage') &&
        <TextareaField
          label={modalInfo.label}
          name={modalInfo.label}
          aria-label={modalInfo.label}
          value={textInputReason}
          onChange={(value) => setTextInputReason(value)}
        />
      }
    </Modal>
  );
};

PackageActionModal.propTypes = {
  correspondence: PropTypes.object,
  packageDocumentType: PropTypes.string,
  veteranInformation: PropTypes.object,
  columns: PropTypes.arrayOf(PropTypes.object),
  modalInfo: PropTypes.object,
  packageActionModal: PropTypes.string,
  closeHandler: PropTypes.func
};

const mapStateToProps = (state) => ({
  correspondence: state.reviewPackage.correspondence,
  packageDocumentType: state.reviewPackage.packageDocumentType.name,
  veteranInformation: state.reviewPackage.veteranInformation
});

export default connect(
  mapStateToProps,
  null,
)(PackageActionModal);
