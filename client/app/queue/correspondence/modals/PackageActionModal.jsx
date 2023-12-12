import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import TextareaField from '../../../components/TextareaField';
import RadioField from '../../../components/RadioField';
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
  const [mergePackageReason, setMergePackageReason] = useState('');
  const [isOtherOption, setIsOtherOption] = useState(false);

  const rows = [
    {
      correspondence,
      packageDocumentType,
      veteranInformation
    }
  ];

  const mergePackageReasonOptions = [
    { displayText: 'Duplicate documents',
      value: 'Duplicate documents' },
    { displayText: 'Documents received on same date realating to same issue(s)/appeal(s)',
      value: 'Documents received' },
    { displayText: 'Other',
      value: 'other' }
  ];

  // Disable submit button unless conditional input is met
  const disableSubmit = () => {
    switch (packageActionModal) {
    case 'mergePackage':
      if (mergePackageReason === 'other') {
        return textInputReason === '';
      }

      return mergePackageReason === '';
    case 'removePackage':
      return textInputReason === '';
    case 'reassignPackage':
      return textInputReason === '';
    default:
      return true;
    }
  };

  const handleMergeReason = (value) => {
    setMergePackageReason(value);
    setIsOtherOption(false);
    if (value === 'other') {
      setIsOtherOption(true);
    }
  };

  const submitHandler = async () => {
    const data = {
      correspondence_id: correspondence.id,
      type: packageActionModal,
      instructions: []
    };

    if (isOtherOption || packageActionModal === 'removePackage' || packageActionModal === 'reassignPackage') {
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
        (packageActionModal === 'mergePackage') &&
        <RadioField
          label={modalInfo.label}
          name="merge-package"
          value={mergePackageReason}
          options={mergePackageReasonOptions}
          onChange={handleMergeReason}
        />
      }
      {
        (isOtherOption || packageActionModal === 'removePackage' || packageActionModal === 'reassignPackage') &&
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
