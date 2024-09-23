import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import TextareaField from '../../../components/TextareaField';
import RadioField from '../../../components/RadioField';
import Table from '../../../components/Table';
import { connect } from 'react-redux';
import ApiUtil from '../../../util/ApiUtil';
import { bindActionCreators } from 'redux';
import { setTaskInstructions, updateLastAction } from '../correspondenceReducer/reviewPackageActions';
import { getPackageActionColumns, getModalInformation } from '../ReviewPackage/utils';
import { useHistory } from 'react-router';

const PackageActionModal = (props) => {
  const {
    packageActionModal,
    correspondence,
    packageDocumentType,
    closeHandler,
  } = props;

  const modalInfo = getModalInformation(packageActionModal);
  const history = useHistory();

  const [textInputReason, setTextInputReason] = useState('');
  const [mergePackageReason, setMergePackageReason] = useState('');
  const [isOtherOption, setIsOtherOption] = useState(false);
  const [radioValue, setRadioValue] = useState('');

  const rows = [
    {
      correspondence,
      packageDocumentType,
    }
  ];

  const mergePackageReasonOptions = [
    { displayText: 'Duplicate documents',
      value: 'Duplicate documents' },
    { displayText: 'Documents received on the same date relating to the same issue(s)/appeal(s)',
      value: 'Documents received' },
    { displayText: 'Other',
      value: 'other' }
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

  const handleMergeReason = (value) => {
    setMergePackageReason(value);
    setIsOtherOption(false);
    if (value === 'other') {
      setIsOtherOption(true);
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

    if (packageActionModal === 'removePackage' || packageActionModal === 'reassignPackage') {
      data.instructions.push(textInputReason);
    }

    if (radioValue && radioValue !== 'Other') {
      data.instructions.push(radioValue);
    }

    if (
      (isOtherOption ||
        packageActionModal === 'removePackage' ||
        packageActionModal === 'reassignPackage' ||
        packageActionModal === 'splitPackage') &&
      textInputReason !== ''
    ) {
      data.instructions.push(textInputReason);
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
        if (packageActionModal === 'removePackage') {
          props.setTaskInstructions(textInputReason);
        }
        props.updateLastAction(packageActionModal);
        history.replace('/queue/correspondence/');
      }
    }
    ).
      catch(() => {
        console.error('Review Package Action already exists');
      });
    setTextInputReason('');
  };

  return (
    <Modal
      title={modalInfo.title}
      buttons={[
        {
          classNames: ['cf-modal-link', 'cf-btn-link'],
          name: 'Cancel',
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
      <span>
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
          label={modalInfo.radioLabel}
          name="merge-package"
          value={mergePackageReason}
          options={mergePackageReasonOptions}
          onChange={handleMergeReason}
        />
      }
      {(packageActionModal === 'splitPackage') && <RadioField
        name="Select a reason for splitting this package"
        options={RadioOptions}
        onChange={onChange}
      />}
      {(isOtherOption ||
        packageActionModal === 'removePackage' ||
        packageActionModal === 'reassignPackage' ||
        radioValue === 'Other') && (
        <TextareaField
          label={modalInfo.label}
          name={modalInfo.label}
          aria-label={modalInfo.label}
          value={textInputReason}
          placeholder={modalInfo.placeholder}
          onChange={(value) => setTextInputReason(value)}
        />
      )}
    </Modal>
  );
};

PackageActionModal.propTypes = {
  correspondence: PropTypes.object,
  packageDocumentType: PropTypes.string,
  columns: PropTypes.arrayOf(PropTypes.object),
  modalInfo: PropTypes.object,
  packageActionModal: PropTypes.string,
  closeHandler: PropTypes.func,
  setTaskInstructions: PropTypes.func,
  updateLastAction: PropTypes.func
};

const mapStateToProps = (state) => ({
  correspondence: state.reviewPackage.correspondence,
  packageDocumentType: state.reviewPackage.packageDocumentType.name,
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setTaskInstructions, updateLastAction
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps,
)(PackageActionModal);
