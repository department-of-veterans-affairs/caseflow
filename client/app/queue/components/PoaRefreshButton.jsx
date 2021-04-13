import React from 'react';
import PropTypes from 'prop-types';
// import { editAppeal, poaSyncDateUpdates } from '../QueueActions';
// import { useDispatch, useSelector } from 'react-redux';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
import { css } from 'glamor';

export const PoaRefreshButton = ({ appealId }) => {
	console.log(appealId)
  const updatePOA = () => {
    // fetch(`/appeals/${appealId}/update_power_of_attorney`)
    //   .then(res => res.json())
    //   .then(
    //     (result) => {
    //       alert = {
    //         type: result.status,
    //         message: result.message
    //       }
    //     }
    //   )

    ApiUtil.patch(`/appeals/${appealId}/update_power_of_attorney`).then((data) => {
      console.log(data.body);
    //   dispatch(editAppeal(appealId, {
    //     nodDate: data.body.nodDate,
    //     docketNumber: data.body.docketNumber,
    //     reason: data.body.changeReason
    //   }));

    //   if (data.body.affectedIssues) {
    //     setIssues({ affectedIssues: data.body.affectedIssues, unaffectedIssues: data.body.unaffectedIssues });
    //     setTimelinessError(true);
    //   } else {
    //     dispatch(editNodDateUpdates(appealId, data.body.nodDateUpdate));
    //     dispatch(showSuccessMessage(successMessage));
    //     onSubmit?.();
    //     window.scrollTo(0, 0);
    //   }
    });
  };

  return (
    <div>
        <Button
            type="button"
            name="Refresh Poa"
            classNames={['cf-push-right']}
            onClick={() => updatePOA()}
          >
            Refresh POA
        </Button>
    </div>
  );
};

PoaRefreshButton.propTypes = {
  powerOfAttorney: PropTypes.shape({
    poa_last_synced_at: PropTypes.string
  })

};
