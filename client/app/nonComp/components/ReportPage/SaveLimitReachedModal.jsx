import React, { useState } from 'react';
import Modal from 'app/components/Modal';
import COPY from 'app/../COPY';
import PropTypes from 'prop-types';
import RadioField from 'app/components/RadioField';

import { useSelector } from 'react-redux';
import { useHistory } from 'react-router-dom';

export const SaveLimitReachedModal = ({ setShowLimitModal }) => {

  const businessLineUrl = useSelector((state) => state.nonComp.businessLineUrl);
  const userSearches = useSelector((state) => state.savedSearch.fetchedSearches?.userSearches);
  const [disableDelete, setDisableDelete] = useState(true);

  const history = useHistory();

  const handleCancel = () => {
    setShowLimitModal(false);
  };

  const onClickDelete = () => {
    // console.log('this will be updated in next ticket');
  };

  const onRadioSelect = (val) => {
    setDisableDelete(false);
  };

  const handleRedirect = () => {
    history.push(`/${businessLineUrl}/searches`);
    setShowLimitModal(false);
  };

  const userSearchesList = () => {
    return (
      userSearches.map((search) =>
        <RadioField
          name="radioFieldSearchGroup"
          options={[{ displayText: search.name, value: search.id }]}
          hideLabel
          onChange={(val) => onRadioSelect(val)}
          vertical
          optionsStyling={{ marginLeft: 5 }} />
      )
    );
  };

  return (
    <Modal title={COPY.SAVE_LIMIT_REACH_TITLE}
      buttons={[
        { classNames: ['cf-modal-link', 'cf-btn-link'],
          name: 'Cancel',
          onClick: handleCancel
        },
        { classNames: ['usa-button', 'cf_add_margin'],
          name: 'Delete',
          disabled: disableDelete,
          onClick: onClickDelete
        },
        { classNames: ['usa-button', 'usa-button-secondary'],
          name: 'View saved searches',
          onClick: handleRedirect
        }
      ]}
      closeHandler={handleCancel}
    >
      {COPY.SAVE_LIMIT_REACH_MESSAGE}
      {userSearchesList()}
    </Modal>);
};

SaveLimitReachedModal.propTypes = {
  setShowLimitModal: PropTypes.func.isRequired
};

export default SaveLimitReachedModal;
