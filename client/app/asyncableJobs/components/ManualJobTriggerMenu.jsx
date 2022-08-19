import React from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import ApiUtil from '../../util/ApiUtil';

const ManualJobTriggerMenu = (props) => {

  const sendJobRequest = (jobType) => {
    ApiUtil.post('api/v1/jobs', { job_type: jobType });
  };

  return (
    <div>
      <h1>Manually Perform Async Jobs</h1>
      {props.availableJobs.map((jobType) => (
        <div>
          <p>{jobType}</p>
          <Button
            name={`trigger-${jobType}-job`}
            onClick={() => sendJobRequest(jobType)}
          >
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
