import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import CancelCavcDashboardChangeModal from './CancelCavcDashboardChangeModal';
import { css } from 'glamor';

const buttonDivStyling = css({
  float: 'right'
});

export const CavcDashboardFooter = (props) => {
  const { userCanEdit, history } = props;
  // const { appealId, userCanEdit, history } = props;
  const [cancelModalIsOpen, setCancelModalIsOpen] = useState(false);

  const closeHandler = () => {
    setCancelModalIsOpen(!cancelModalIsOpen);
  };

  // const cancel = () => {
  //   history.goBack();
  // };

  const save = () => {
    history.goBack();
  };

  if (userCanEdit) {
    return (
      // <div>
      //   <Button onClick={closeHandler}>Cancel</Button>
      //   <Button onClick={save}>Save Changes</Button>
      //   {
      //     (cancelModalIsOpen) &&
      //     <CancelCavcDashboardChangeModal closeHandler={closeHandler} {...props} />
      //   }
      <div {...buttonDivStyling}>
        <Button linkStyling onClick={closeHandler}>Cancel</Button>
        <Button onClick={save}>Save Changes</Button>
        {
          (cancelModalIsOpen) &&
          <CancelCavcDashboardChangeModal closeHandler={closeHandler} {...props} />
        }
      </div>
    );
  }

  return (
    // todo check if the history.goback causes issues
    // <div {...buttonDivStyling}>
    //   <Button onClick={cancel}>Return to Case Details</Button>
    // </div>
    <div {...buttonDivStyling}>
      <Button onClick={() => history.goBack()}>Return to Case Details</Button>
    </div>
  );
};

CavcDashboardFooter.propTypes = {
  // appealId: PropTypes.string,
  userCanEdit: PropTypes.bool.isRequired,
  // Router inherited props
  history: PropTypes.object
};
