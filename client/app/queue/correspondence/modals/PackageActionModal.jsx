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
import RadioField from '../../../components/RadioField';

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
  const [radioValue, setRadioValue] = useState('');

  const rows = [
    {
      correspondence,
      packageDocumentType,
      veteranInformation
    }
  ];

  const RadioOptions = [
    { displayText: 'Package contains documents related to more than one person.',
      value: 'Package contains documents related to more than one person.' },
    { displayText: 'Package contains documents that must be processed by multiple business lines.',
      value: 'Package contains documents that must be processed by multiple business lines.' },
    { displayText: 'Other',
      value: 'Other' }
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
    case 'reassignPackage':
      return textInputReason === '';
    case 'splitPackage': {
      const isRadioDisabled = radioValue === '' || radioValue === 'Other';

      return isRadioDisabled ? textInputReason === '' : false;
    }
    default:
      return true;
    }
  };

  const onChange = (event) => {
    setRadioValue(event);
  };

  const submitHandler = async () => {
    const data = {
      correspondence_id: correspondence.id,
      type: packageActionModal,
      instructions: []
    };

    if (radioValue && radioValue !== 'Other') {
      data.instructions.push(radioValue);
    }

    if (
      (packageActionModal === 'removePackage' ||
        packageActionModal === 'reassignPackage' ||
        packageActionModal === 'splitPackage') &&
      textInputReason !== ''
    ) {
      data.instructions.push(textInputReason);
    }
    ApiUtil.post(`/queue/correspondence/${correspondence.uuid}/task`, { data }).then((response) => {
      props.closeHandler(null);
      if (response.ok) {
        history.push('/queue/correspondence');
      }
    }
    ).
      catch(() => {
        console.error('Review Package Action already exists');
      });
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
      {(packageActionModal === 'splitPackage') && <RadioField
        name="Select a reason for splitting this package"
        options={RadioOptions}
        onChange={onChange}
      />}
      {(packageActionModal === 'removePackage' ||
        packageActionModal === 'reassignPackage' ||
        radioValue === 'Other') && (
        <TextareaField
          label={modalInfo.label}
          name={modalInfo.label}
          aria-label={modalInfo.label}
          value={textInputReason}
          onChange={(value) => setTextInputReason(value)}
        />
      )}
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
