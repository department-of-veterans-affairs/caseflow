import React, { useState, useEffect } from 'react';
import ApiUtil from '../util/ApiUtil';
import COPY from '../../COPY';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SearchableDropdown from '../components/SearchableDropdown';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { LOGO_COLORS } from '../constants/AppConstants';
import { dvcTeamAdded } from './teamManagement/teamManagement.slice';
import {
  requestSave,
  resetErrorMessages,
  resetSuccessMessages,
  showErrorMessage
} from './uiReducer/uiActions';
import { withRouter } from 'react-router-dom';
import QueueFlowModal from './components/QueueFlowModal';

export const AddDvcTeamModal = (props) => {

  const [usersWithoutDvcTeam, setUsersWithoutDvcTeam] = useState([]);
  const [selectedDvc, setSelectedDvc] = useState(null);

  // mount effect
  useEffect(() => {
    props.resetSuccessMessages();
    props.resetErrorMessages();
  }, []);

  // unmount effect
  useEffect(() => () => props.resetErrorMessages(), []);

  const loadingPromise = async () => {
    const resp = await ApiUtil.get('/users?role=non_dvcs');

    return setUsersWithoutDvcTeam(resp.body.non_dvcs.data);
  };

  const selectDvc = (value) => setSelectedDvc(value);

  const formatName = (user) => `${user.attributes.full_name} (${user.attributes.css_id})`;

  const dropdownOptions = () =>
    usersWithoutDvcTeam.map((user) => ({ label: formatName(user),
      value: user }));

  const submit = () => props.requestSave(`/team_management/dvc_team/${selectedDvc.value.id}`).
    then((resp) => props.dvcTeamAdded(resp.body?.org)).
    catch();

  return (
    <QueueFlowModal
      title={COPY.TEAM_MANAGEMENT_ADD_DVC_TEAM_MODAL_TITLE}
      pathAfterSubmit="/team_management"
      submit={submit}
    >
      <LoadingDataDisplay
        createLoadPromise={loadingPromise}
        loadingComponentProps={{
          spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
          message: 'Loading users...'
        }}
        failStatusMessageProps={{ title: 'Unable to load users' }}>
        <SearchableDropdown
          name={COPY.TEAM_MANAGEMENT_SELECT_DVC_LABEL}
          hideLabel
          searchable
          placeholder={COPY.TEAM_MANAGEMENT_SELECT_DVC_LABEL}
          value={selectedDvc}
          onChange={selectDvc}
          options={dropdownOptions()} />
      </LoadingDataDisplay>
    </QueueFlowModal>
  );
};

AddDvcTeamModal.propTypes = {
  dvcTeamAdded: PropTypes.func,
  requestSave: PropTypes.func,
  resetErrorMessages: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  showErrorMessage: PropTypes.func
};

const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  dvcTeamAdded,
  requestSave,
  resetErrorMessages,
  resetSuccessMessages,
  showErrorMessage
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(AddDvcTeamModal));
