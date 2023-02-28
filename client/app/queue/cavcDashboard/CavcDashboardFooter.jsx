import React from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
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

  const cancel = () => {
    history.goBack();
  };

  const save = async () => {
    const result = await saveDashboardData(cavcDashboards, checkedBoxes);

    if (result === true) {
      history.goBack();
    }
  };

  if (userCanEdit) {
    return (
      <div {...buttonDivStyling}>
        <Button linkStyling onClick={cancel}>Cancel</Button>
        <Button onClick={save} disabled={saveDisabled} >Save Changes</Button>
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
  initialState: PropTypes.object,
  cavcDashboards: PropTypes.arrayOf(PropTypes.object),
  checkedBoxes: PropTypes.oneOfType([PropTypes.object, PropTypes.arrayOf(PropTypes.object)]),
  // Router inherited props
  history: PropTypes.object
};
