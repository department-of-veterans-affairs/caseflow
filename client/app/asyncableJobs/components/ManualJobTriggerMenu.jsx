import React from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import ApiUtil from '../../util/ApiUtil';
import StringUtil from '../../util/StringUtil';

const ManualJobTriggerMenu = (props) => {

  const sendJobRequest = (jobType) => {
    ApiUtil.post('api/v1/jobs', { data: { job_type: jobType } });
  };

  return (
    <div>
      <h1>Manually Perform Async Jobs</h1>
      <table>
        {props.supportedJobs.map((jobType) => (
          <tr>
            <td>
              <h3>{StringUtil.snakeCaseToCapitalized(jobType)}</h3>
            </td>
            <td>
              <Button
                name={`trigger-${jobType}-job`}
                onClick={() => sendJobRequest(jobType)}
              >
                Perform Now
              </Button>
            </td>
          </tr>
        ))}
      </table>
    </div>
  );
};

ManualJobTriggerMenu.propTypes = {
  supportedJobs: PropTypes.arrayOf(
    PropTypes.string
  )
};

export default ManualJobTriggerMenu;
