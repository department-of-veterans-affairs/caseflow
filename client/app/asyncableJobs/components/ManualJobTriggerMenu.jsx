import React from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';

const ManualJobTriggerMenu = (props) => {

  return (
    <div>
      <h1>Manually Perform Async Jobs</h1>
      {props.availableJobs.map((jobType) => (
        <div>
          <p>{jobType}</p>
          <Button>
            Perform Now
          </Button>
        </div>
      ))}
    </div>
  );
};

ManualJobTriggerMenu.propTypes = {
  availableJobs: PropTypes.arrayOf(
    PropTypes.string
  )
};

export default ManualJobTriggerMenu;
