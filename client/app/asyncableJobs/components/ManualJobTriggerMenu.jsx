import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import StringUtil from '../../util/StringUtil';
import classNames from 'classnames';

const ManualJobTriggerMenu = (props) => {

  const [jobTriggered, setJobTriggered] = useState(null);

  const renderMessage = () => {
    if (jobTriggered) {
      const manualJobBannerClasses = classNames({
        success: props.manualJobSuccess,
        fail: !props.manualJobSuccess,
      }, 'manual-job-banner');

      return (
        <div className={manualJobBannerClasses}>
          Manual run of <strong>{StringUtil.snakeCaseToCapitalized(jobTriggered)}</strong> returned a{' '}
          <strong>{props.manualJobStatus}</strong>
        </div>
      );
    }

    return null;
  };

  return (
    <div className="tab-border scheduled-jobs-tab">
      <br />
      <h1>Manually Perform Scheduled Async Jobs</h1>
      {renderMessage()}
      <table>
        <tbody className="manual-job-table">
          {props.supportedJobs.map((jobType) => (
            <tr>
              <td>
                <h3>{StringUtil.snakeCaseToCapitalized(jobType)}</h3>
              </td>
              <td>
                <Button
                  name={`trigger-${jobType}-job`}
                  onClick={() => {
                    setJobTriggered(jobType);
                    props.sendJobRequest(jobType);
                  }}
                >
                Perform Now
                </Button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

ManualJobTriggerMenu.propTypes = {
  supportedJobs: PropTypes.arrayOf(
    PropTypes.string
  ),
  sendJobRequest: PropTypes.func.isRequired,
  manualJobStatus: PropTypes.number,
  manualJobId: PropTypes.number,
  manualJobSuccess: PropTypes.bool
};

export default ManualJobTriggerMenu;
