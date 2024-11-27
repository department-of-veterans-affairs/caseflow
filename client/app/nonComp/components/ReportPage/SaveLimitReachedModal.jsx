import React, { useState } from 'react';
import Modal from 'app/components/Modal';
import COPY from 'app/../COPY';
import PropTypes from 'prop-types';
import RadioField from 'app/components/RadioField';
import { selectSavedSearch } from 'app/nonComp/actions/savedSearchSlice';
import { isEmpty } from 'lodash';
import { useDispatch } from 'react-redux';

export const SaveLimitReachedModal = ({
  userSearches,
  handleCancel,
  onClickDelete,
  handleRedirect
}) => {
  const dispatch = useDispatch();

  const [selectedRow, setSelectedRow] = useState([]);

  const onRadioSelect = (val) => {
    // eslint-disable-next-line radix
    const selectedData = userSearches.find((search) => parseInt(search.id) === parseInt(val));

    setSelectedRow(selectedData);

    dispatch(selectSavedSearch(selectedData));
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
          disabled: isEmpty(selectedRow),
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
  userSearches: PropTypes.array,
  handleCancel: PropTypes.func.isRequired,
  onClickDelete: PropTypes.func.isRequired,
  handleRedirect: PropTypes.func.isRequired,
};

export default SaveLimitReachedModal;
