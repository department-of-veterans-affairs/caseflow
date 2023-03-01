import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import CancelCavcDashboardChangeModal from './CancelCavcDashboardChangeModal';
import { css } from 'glamor';
import _ from 'lodash';

const buttonDivStyling = css({
  float: 'right'
});

export const CavcDashboardFooter = (props) => {
  const {
    userCanEdit,
    history,
    saveDashboardData,
    initialState,
    cavcDashboards,
    checkedBoxes
  } = props;

  const saveDisabled = _.isEqual(initialState.cavc_dashboards, cavcDashboards) &&
                       _.isEqual(initialState.checked_boxes, checkedBoxes);

  const [cancelModalIsOpen, setCancelModalIsOpen] = useState(false);

  const closeHandler = () => {
    setCancelModalIsOpen(!cancelModalIsOpen);
  };

  const save = async () => {
    const result = await saveDashboardData(cavcDashboards, checkedBoxes);

    if (result === true) {
      history.goBack();
    }
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
        <Button onClick={save} disabled={saveDisabled} >Save Changes</Button>
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
  saveDashboardData: PropTypes.func,
  initialState: PropTypes.object,
  cavcDashboards: PropTypes.arrayOf(PropTypes.object),
  checkedBoxes: PropTypes.oneOfType([PropTypes.object, PropTypes.arrayOf(PropTypes.object)]),
  // Router inherited props
  history: PropTypes.object
};
