import React from 'react';
import ReduxBase from '../components/ReduxBase';
import ManageEstablishClaim from './ManageEstablishClaim';
import manageEstablishClaimReducer, { getManageEstablishClaimInitialState } from './reducers';

const ManageEstablishClaimWrapper = (props) => {
  const initialState = getManageEstablishClaimInitialState(props);

  return <ReduxBase reducer={manageEstablishClaimReducer} initialState={initialState}>
    <ManageEstablishClaim {...props} />
  </ReduxBase>;
};

export default ManageEstablishClaimWrapper;
