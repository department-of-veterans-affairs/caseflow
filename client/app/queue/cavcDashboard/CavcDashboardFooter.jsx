import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import CancelCavcDashboardChangeModal from './CancelCavcDashboardChangeModal';

export const CavcDashboardFooter = (props) => {
  const { userCanEdit, history } = props;
  // const { appealId, userCanEdit, history } = props;
  const [cancelModalIsOpen, setCancelModalIsOpen] = useState(false);

  const closeHandler = () => {
    setCancelModalIsOpen(!cancelModalIsOpen);
  };

  //      history.push(`/queue/appeals/${appeal.externalId}`);
  //  const cancel = () => history.goBack();

  const cancel = () => {
    history.goBack();
  };

  const save = () => {
    history.goBack();
  };

  if (userCanEdit) {
    return (
      <>
        <Button onClick={closeHandler}>Cancel</Button>
        <Button onClick={save}>Save Changes</Button>
        {
          (cancelModalIsOpen) &&
          <CancelCavcDashboardChangeModal closeHandler={closeHandler} {...props} />
        }
      </>
    );
  }

  return (
    <>
      <Button onClick={cancel}>Close</Button>
    </>
  );
};

CavcDashboardFooter.propTypes = {
  // appealId: PropTypes.string,
  userCanEdit: PropTypes.bool.isRequired,
  // Router inherited props
  history: PropTypes.object
};
