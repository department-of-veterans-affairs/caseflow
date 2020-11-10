import React from 'react';
import { useSelector } from 'react-redux';
// import PropTypes from 'prop-types';
import COPY from '../../COPY';

import QueueFlowPage from './components/QueueFlowPage';
import { appealWithDetailSelector } from './selectors';
import TextField from '../components/TextField';
import SearchableDropdown from '../components/SearchableDropdown';
import RadioField from '../components/RadioField';

const AddCavcRemandView = () => {

  // const appeal = useSelector((state) => appealWithDetailSelector(state, { appealId }));

  return (
    // <QueueFlowPage>
    <>
      <h1>{COPY.ADD_CAVC_PAGE_TITLE}</h1>
      <p>{COPY.ADD_CAVC_DESCRIPTION}</p>
      <h4>{COPY.CAVC_DOCKET_NUMBER_LABEL}</h4>
      <h4>{COPY.CAVC_ATTORNEY_LABEL}</h4>
      <SearchableDropdown />
      {/* <RadioField /> */}
      <TextField />
    </>
    // </QueueFlowPage>
  );
};

// AddCavcRemandView.propTypes = {

// };

export default AddCavcRemandView;
