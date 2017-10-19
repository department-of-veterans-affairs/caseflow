import React from 'react';
import { Provider } from 'react-redux';
import { createManageEstablishClaimStore } from './reducers/store';
import ManageEstablishClaim from './ManageEstablishClaim';

const ManageEstablishClaimWrapper = (props) => {
  const store = createManageEstablishClaimStore(props);

  return <Provider store={store}>
    <ManageEstablishClaim {...props} />
  </Provider>;
};

export default ManageEstablishClaimWrapper;
