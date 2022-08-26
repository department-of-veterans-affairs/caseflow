import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import StringUtil from '../../util/StringUtil';
import classNames from 'classnames';
import LoadingContainer from '../../components/LoadingContainer';
import { LOGO_COLORS } from '../../constants/AppConstants';

const ManualJobTriggerMenu = (props) => {

  const [loading, setLoading] = useState(false);
  const [manualJobType, setManualJobType] = useState(null);

  useEffect(() => {
    setManualJobType(props.manualJobType);
    if (props.manualJobType) {
      setLoading(false);
    }

  }, [props.manualJobType]);

  const renderMessage = () => {
    if (manualJobType) {
      const manualJobBannerClasses = classNames({
        success: props.manualJobSuccess,
        fail: !props.manualJobSuccess,
      }, 'manual-job-banner');

      return (
        <div className={manualJobBannerClasses}>
          Manual run of <strong>{StringUtil.snakeCaseToCapitalized(manualJobType)}</strong> returned a{' '}
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
      {loading &&
        <LoadingContainer color={LOGO_COLORS.QUEUE.ACCENT}>
          <div className="loading-div">
            Job is Running...
          </div>
        </LoadingContainer>
      }
      {!loading && (<>
        {renderMessage()}
        <table>
          <tbody className="manual-job-table">
            {props.supportedJobs.map((jobType) => (
              <tr key={`${jobType}-row`}>
                <td>
                  <h3>{StringUtil.snakeCaseToCapitalized(jobType)}</h3>
                </td>
                <td>
                  <Button
                    name={`trigger-${jobType}-job`}
                    onClick={() => {
                      setLoading(true);
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
      </>)}
    </div>
  );
};

ManualJobTriggerMenu.propTypes = {
  supportedJobs: PropTypes.arrayOf(
    PropTypes.string
  ),
  sendJobRequest: PropTypes.func.isRequired,
  manualJobStatus: PropTypes.number,
  manualJobSuccess: PropTypes.bool,
  manualJobType: PropTypes.string,
};

export default ManualJobTriggerMenu;
