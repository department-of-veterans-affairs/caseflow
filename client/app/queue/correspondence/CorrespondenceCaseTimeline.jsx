import React from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';
import CorrespondenceDetails from '././CorrespondenceDetails.jsx';
import { loadCorrespondence } from './correspondenceReducer/correspondenceActions';

export const CorrespondenceCaseTimeline = ({ correspondence }) => {
  const tabs = useSelector((state) => loadCorrespondence(state, {  }));

  return (
    <React.Fragment>
      <table id="case-timeline-table" summary="layout table">
        <tbody>
          <CorrespondenceDetails correspondence={correspondence}
            tabsList={tabs}
            timeline
            statusSplit
          />
        </tbody>
      </table>
    </React.Fragment>
  );
};

CorrespondenceDetails.propTypes = {
  loadCorrespondence: PropTypes.func,
  correspondence: PropTypes.object
};
