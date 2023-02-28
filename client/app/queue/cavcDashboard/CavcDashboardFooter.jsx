import React from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import { css } from 'glamor';

const buttonDivStyling = css({
  float: 'right'
});

export const CavcDashboardFooter = (props) => {
  const { userCanEdit, history, saveDashboardData, cavcDashboards, checkedBoxes } = props;

  const cancel = () => {
    history.goBack();
  };

  const save = () => {
    const result = saveDashboardData(cavcDashboards, checkedBoxes);

    if (result === true) {
      history.goBack();
    }
  };

  if (userCanEdit) {
    return (
      <div {...buttonDivStyling}>
        <Button linkStyling onClick={cancel}>Cancel</Button>
        <Button onClick={save}>Save Changes</Button>
      </div>
    );
  }

  return (
    <div {...buttonDivStyling}>
      <Button onClick={() => history.goBack()}>Return to Case Details</Button>
    </div>
  );
};

CavcDashboardFooter.propTypes = {
  userCanEdit: PropTypes.bool.isRequired,
  saveDashboardData: PropTypes.func,
  cavcDashboards: PropTypes.arrayOf(PropTypes.object),
  checkedBoxes: PropTypes.oneOfType([PropTypes.object, PropTypes.arrayOf(PropTypes.object)]),
  // Router inherited props
  history: PropTypes.object
};
