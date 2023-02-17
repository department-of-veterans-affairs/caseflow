import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { getCavcDashboardById } from './cavcDashboardSelectors';
import CavcDashboardDetails from './CavcDashboardDetails';
import CavcDashboardIssuesSection from './CavcDashboardIssuesSection';
import Button from '../../components/Button';
import AddCavcDashboardIssueModal from './AddCavcDashboardIssueModal';

export const CavcDashboardTab = (props) => {
  // const { userCanEdit } = props;
  const { userCanEdit } = props;
  const [modalIsOpen, setModalIsOpen] = useState(false);

  const closeHandler = () => {
    setModalIsOpen(!modalIsOpen);
  };

  return (
    <>
      <CavcDashboardDetails {...props} />
      <div><CavcDashboardIssuesSection {...props} /></div>
      {
        (userCanEdit) &&
        <Button
          type="button"
          name="Add Issue Button"
          classNames="usa-button-secondary"
          onClick={() => setModalIsOpen(true)}
        >
            Add Issue
        </Button>
      }
      {
        (modalIsOpen) &&
        <AddCavcDashboardIssueModal closeHandler={closeHandler} />
      }
    </>
  );
};

CavcDashboardTab.propTypes = {
  dashboardId: PropTypes.number,
  dashboard: PropTypes.object,
  canEditCavcDashboards: PropTypes.bool,
  userCanEdit: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => {
  return {
    dashboard: getCavcDashboardById(state, { dashboardId: ownProps.dashboardId }),
    userCanEdit: state.ui.canEditCavcDashboards
  };
};

// const mapDispatchToProps = (dispatch) => {

// };

export default connect(
  mapStateToProps,
  // mapDispatchToProps
)(CavcDashboardTab);
