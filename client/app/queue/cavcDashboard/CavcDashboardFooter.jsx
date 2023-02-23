import React from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import { css } from 'glamor';

const closeButtonStyling = css({
  float: 'right'
});

export const CavcDashboardFooter = (props) => {
  const { userCanEdit, history } = props;

  const cancel = () => {
    history.goBack();
  };

  const save = () => {
    history.goBack();
  };

  if (userCanEdit) {
    return (
      <>
        <Button
          linkStyling
          onClick={cancel}
        >Cancel</Button>
        <Button onClick={save}>Save Changes</Button>
      </>
    );
  }

  return (
    <>
      <Button
        {...closeButtonStyling}
        onClick={() => history.goBack()
        }
      >Close</Button>
    </>
  );
};

CavcDashboardFooter.propTypes = {
  userCanEdit: PropTypes.bool.isRequired,
  // Router inherited props
  history: PropTypes.object
};
