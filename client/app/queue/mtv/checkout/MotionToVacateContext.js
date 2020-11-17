import React, { useState } from 'react';
import PropTypes from 'prop-types';

const defaultState = {};

// This pattern allows us to access a shared object state using familiar functions
// Components that consume this context can simply use this syntax:
// const [state, setState] = useContext(MotionToVacateContext);
// setState({...state, foo: 'bar'});
export const MotionToVacateContext = React.createContext([{}, () => null]);

export const MotionToVacateContextProvider = ({ initialState = { ...defaultState }, children }) => {
  const [state, setState] = useState(initialState);

  return <MotionToVacateContext.Provider value={[state, setState]}>{children}</MotionToVacateContext.Provider>;
};
MotionToVacateContextProvider.propTypes = {
  initialState: PropTypes.object,
  children: PropTypes.element
};
