import React from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';

export const CavcDashboardFooter = (props) => {
  const { userCanEdit, history, saveDashboardData, cavcDashboards, checkedBoxes } = props;

  //      history.push(`/queue/appeals/${appeal.externalId}`);
  //  const cancel = () => history.goBack();

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
      <>
        <Button onClick={cancel}>Cancel</Button>
        <Button onClick={save}>Save Changes</Button>
      </>
    );
  }

  return (
    <>
      <Button onClick={() => history.goBack()}>Close</Button>
    </>
  );
};

CavcDashboardFooter.propTypes = {
  userCanEdit: PropTypes.bool.isRequired,
  saveDashboardData: PropTypes.func,
  cavcDashboards: PropTypes.arrayOf(PropTypes.object),
  checkedBoxes: PropTypes.arrayOf(PropTypes.object),
  // Router inherited props
  history: PropTypes.object
};
