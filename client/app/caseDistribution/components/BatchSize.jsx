import React, { useEffect, useState } from 'react';
import { useSelector } from 'react-redux';
import PropTypes from 'prop-types';
// import { ACTIONS } from 'app/caseDistribution/reducers/levers/leversActionTypes';
import NumberField from 'app/components/NumberField';
import leverInputValidation from './LeverInputValidation';
import COPY from '../../../COPY';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';
import { checkIfOtherChangesExist } from '../utils';

const BatchSize = (props) => {
  const { isAdmin } = props;

  const backendLevers = useSelector((state) => state.caseDistributionLevers.backendLevers.batch);
  const storeLevers = useSelector((state) => state.caseDistributionLevers.levers.batch);
  const [errorMessagesList, setErrorMessages] = useState({});
  const [batchSizeLevers, setBatchSizeLevers] = useState(storeLevers);

  useEffect(() => {
    setBatchSizeLevers(storeLevers);
  }, [storeLevers]);

  const updateLever = (index) => (event) => {
    const levers = batchSizeLevers.map((lever, i) => {
      if (index === i) {

        let initialLever = backendLevers.find((original) => original.item === lever.item);

        let validationResponse = leverInputValidation(lever, event, errorMessagesList, initialLever);

        if (validationResponse.statement === ACD_LEVERS.DUPLICATE) {

          if (checkIfOtherChangesExist(lever)) {
            lever.value = event;
            setErrorMessages(validationResponse.updatedMessages);

            // leverStore.dispatch({
            //   type: ACTIONS.UPDATE_LEVER_VALUE,
            //   updated_lever: { item: lever.item, value: event },
            //   hasValueChanged: false,
            //   validChange: true
            // });
          } else {

            lever.value = event;
            setErrorMessages(validationResponse.updatedMessages);

            // leverStore.dispatch({
            //   type: ACTIONS.UPDATE_LEVER_VALUE,
            //   updated_lever: { item: lever.item, value: event },
            //   hasValueChanged: false,
            //   validChange: false
            // });
          }

        }
        if (validationResponse.statement === ACD_LEVERS.SUCCESS) {

          lever.value = event;
          setErrorMessages(validationResponse.updatedMessages);
          // leverStore.dispatch({
          //   type: ACTIONS.UPDATE_LEVER_VALUE,
          //   updated_lever: { item: lever.item, value: event },
          //   validChange: true
          // });

          return lever;
        }
        if (validationResponse.statement === ACD_LEVERS.FAIL) {
          lever.value = event;
          setErrorMessages(validationResponse.updatedMessages);

          // leverStore.dispatch({
          //   type: ACTIONS.UPDATE_LEVER_VALUE,
          //   updated_lever: { item: lever.item, value: event },
          //   validChange: false
          // });

          return lever;
        }
      }

      return lever;
    });

    setBatchSizeLevers(levers);
  };

  return (
    <div className='lever-content'>
      <div className='lever-head'>
        <h2>{COPY.CASE_DISTRIBUTION_BATCHSIZE_H2_TITLE}</h2>
        <div className='lever-left'><strong>{COPY.CASE_DISTRIBUTION_BATCHSIZE_LEVER_LEFT_TITLE}</strong></div>
        <div className='lever-right'><strong>{COPY.CASE_DISTRIBUTION_BATCHSIZE_LEVER_RIGHT_TITLE}</strong></div>
      </div>
      {batchSizeLevers && batchSizeLevers.map((lever, index) => (
        <div className='active-lever' key={`${lever.item}-${index}`}>
          <div className='lever-left'>
            <strong className={lever.is_disabled_in_ui ? 'lever-disabled' : 'lever-active'}>
              {lever.title}
            </strong>
            <p className={lever.is_disabled_in_ui ? 'lever-disabled' : 'lever-active'}>
              {lever.description}
            </p>
          </div>
          <div className={`lever-right batch-lever-num-sec`}>
            {isAdmin ?
              <NumberField
                name={lever.item}
                label={lever.unit}
                isInteger
                readOnly={lever.is_disabled_in_ui}
                value={lever.value}
                errorMessage={errorMessagesList[lever.item]}
                onChange={updateLever(index, lever.item, lever.item)}
                tabIndex={lever.is_disabled_in_ui ? -1 : null}
              /> :
              <label className={lever.is_disabled_in_ui ? 'lever-disabled' : 'lever-active'}>
                {lever.value} {lever.unit}
              </label>
            }
          </div>
        </div>
      ))}
      <h4 className='footer-styling'>{COPY.CASE_DISTRIBUTION_FOOTER_ASTERISK_DESCRIPTION}</h4>
      <div className="cf-help-divider"></div>
    </div>
  );
};

BatchSize.propTypes = {
  isAdmin: PropTypes.bool.isRequired
};

export default BatchSize;
