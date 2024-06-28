import React, { useEffect, useRef } from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../../COPY';
import Alert from '../../../components/Alert';
import {
  setAutoAssignmentAlertBanner,
  setAutoAssignButtonDisabled
} from '../correspondenceReducer/reviewPackageActions';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import ApiUtil from '../../../util/ApiUtil';
import CORRESPONDENCE_AUTO_ASSIGNMENT from '../../../../../client/constants/CORRESPONDENCE_AUTO_ASSIGNMENT';

const AutoAssignAlertBanner = (props) => {
  const {
    batchId,
    bannerAlert,
  } = { ...props };

  const AUTO_ASSIGN_POLLING_INTERVAL = 60000;
  const intervalIdRef = useRef();

  const clearIntervalRef = () => {
    clearInterval(intervalIdRef.current);
    intervalIdRef.current = null;
  };

  const handleBatchAutoAssignmentBanner = async (response) => {
    if (response.status === CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.error) {
      const bannerPayload = {
        message: response.error_message.message
      };

      if (response.error_message.message.includes(COPY.BAAA_ERROR_MESSAGE)) {
        bannerPayload.type = 'error';
        bannerPayload.title = COPY.BAAA_FAILED_TITLE;
      } else {
        bannerPayload.type = 'warning';
        bannerPayload.title = COPY.BAAA_UNSUCCESSFUL_TITLE;
      }

      props.setAutoAssignmentAlertBanner(bannerPayload);
    } else if (response.status === CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.completed) {
      props.setAutoAssignmentAlertBanner({
        title: `You have successfully assigned ${response.number_assigned} correspondences`,
        message: COPY.BAAA_SUCCESS_MESSAGE,
        type: 'success'
      });
    } else {
      props.setAutoAssignmentAlertBanner({
        type: 'pending'
      });
    }
  };

  const fetchAutoAssignBannerInfo = async () => {
    if (batchId) {
      try {
        const response = await ApiUtil.get(`/queue/correspondence/${batchId}/auto_assign_status`);
        const data = await response.body;

        handleBatchAutoAssignmentBanner(data);
      } catch (error) {
        clearIntervalRef();
        console.error('Failed to fetch auto assign banner info', error);
      }
    }
  };

  // UseEffect to trigger an immediate fetch after button click
  useEffect(() => {
    fetchAutoAssignBannerInfo();

    // setInterval in useRef to clearInterval() outside local scope of useEffect
    // and removes an extra async call from being added to the call stack
    if (!intervalIdRef.current) {
      intervalIdRef.current = setInterval(() => {
        fetchAutoAssignBannerInfo();
      }, AUTO_ASSIGN_POLLING_INTERVAL);
    }

    return () => {
      clearIntervalRef();
    };
  }, [batchId]);

  useEffect(() => {
    if (bannerAlert.type !== 'pending' && bannerAlert.message) {
      clearIntervalRef();
      props.setAutoAssignButtonDisabled(false);
    }
  }, [bannerAlert]);

  return (
    <>
      {batchId && bannerAlert.message &&
        <Alert
          type={bannerAlert.type}
          title={bannerAlert.title}
          message={bannerAlert.message}
          scrollOnAlert={false}
          lowerMargin
        />
      }
    </>
  );
};

AutoAssignAlertBanner.propTypes = {
  setAutoAssignmentAlertBanner: PropTypes.func,
  setAutoAssignButtonDisabled: PropTypes.func
};

const mapStateToProps = (state) => ({
  batchId: state.reviewPackage.autoAssign.batchId,
  bannerAlert: state.reviewPackage.autoAssign.bannerAlert
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    setAutoAssignmentAlertBanner,
    setAutoAssignButtonDisabled
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(AutoAssignAlertBanner);
