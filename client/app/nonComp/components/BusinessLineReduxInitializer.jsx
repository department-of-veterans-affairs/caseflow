import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import { useLocation } from 'react-router-dom';
import { fetchBusinessLineInformation } from '../reducers';

const BusinessLineReduxInitializer = ({ children }) => {
  const dispatch = useDispatch();
  const businessLineConfig = useSelector((state) => state.nonComp.businessLineConfig);
  const [isLoading, setIsLoading] = useState(true);

  const location = useLocation();

  const pathParts = location.pathname.split('/');
  const orgUrl = pathParts[1];

  useEffect(() => {
    if (businessLineConfig) {
      setIsLoading(false);
    } else {
      dispatch(fetchBusinessLineInformation(orgUrl)).finally(() => {
        setIsLoading(false);
      });
    }
  }, [businessLineConfig, dispatch]);

  if (isLoading) {
    return <div>Loading...</div>;
  }

  return <>{children}</>;
};

BusinessLineReduxInitializer.propTypes = {
  children: PropTypes.node
};

export default BusinessLineReduxInitializer;
