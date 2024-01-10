import React, { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
// import { ACTIONS } from 'app/caseDistribution/reducers/levers/leversActionTypes';
import { css } from 'glamor';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';
import NumberField from 'app/components/NumberField';
import leverInputValidation from './LeverInputValidation';
import COPY from '../../../COPY';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';
import { checkIfOtherChangesExist } from '../utils';
import { getLeversByGroup } from '../reducers/levers/leversSelector';
import { Constant } from '../constants';
import { updateLeverState } from '../reducers/levers/leversActions';

const BatchSize = (props) => {
  const { isAdmin } = props;
  const leverNumberDiv = css({
    '& .cf-form-int-input': { width: 'auto', display: 'inline-block', position: 'relative' },
    '& .cf-form-int-input .input-container': { width: 'auto', display: 'inline-block', verticalAlign: 'middle' },
    '& .cf-form-int-input label': { position: 'absolute', bottom: '8px', left: '75px' },
    '& .usa-input-error label': { bottom: '15px', left: '89px' }
  });

  const errorMessages = {};
  const dispatch = useDispatch();
  const theState = useSelector((state) => state);
  const storeLevers = getLeversByGroup(theState, Constant.LEVERS, Constant.BATCH);
  const [errorMessagesList] = useState(errorMessages);
  const [batchSizeLevers, setBatchSizeLevers] = useState(storeLevers);

  useEffect(() => {
    setBatchSizeLevers(storeLevers);
  }, [storeLevers]);

  const updateLever = (index) => (event) => {
    setBatchSizeLevers((prevLevers) =>
      prevLevers.map((lever, i) => {
        if (index === i) {
          console.log('Updating Lever:', lever);
          const initialLever = theState.backendLevers.find((backendLever) => backendLever.item === lever.item);
          console.log('Initial Lever:', lever.item);
          const validationResponse = leverInputValidation(lever, event, errorMessagesList, initialLever);

          if (validationResponse.statement === ACD_LEVERS.SUCCESS || validationResponse.statement === ACD_LEVERS.FAIL) {
            // dispatch(updateLeverState(Constant.BATCH, lever.item, event));
          } else if (validationResponse.statement === ACD_LEVERS.DUPLICATE && checkIfOtherChangesExist(lever)) {
            // dispatch(updateLeverState(Constant.BATCH, lever.item, event));
          }
        }

        return lever;
      })
    );
  };

  return (
    <div className={styles.leverContent}>
      <div className={styles.leverHead}>
        <h2>{COPY.CASE_DISTRIBUTION_BATCHSIZE_H2_TITLE}</h2>
        <div className={styles.leverLeft}><strong>{COPY.CASE_DISTRIBUTION_BATCHSIZE_LEVER_LEFT_TITLE}</strong></div>
        <div className={styles.leverRight}><strong>{COPY.CASE_DISTRIBUTION_BATCHSIZE_LEVER_RIGHT_TITLE}</strong></div>
      </div>
      {batchSizeLevers && batchSizeLevers.map((lever, index) => (
        <div className={styles.activeLever} key={`${lever.item}-${index}`}>
          <div className={styles.leverLeft}>
            <strong className={lever.is_disabled_in_ui ? styles.leverDisabled : styles.leverActive}>
              {lever.title}
            </strong>
            <p className={lever.is_disabled_in_ui ? styles.leverDisabled : styles.leverActive}>
              {lever.description}
            </p>
          </div>
          <div className={`${styles.leverRight} ${leverNumberDiv}`}>
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
              <label className={lever.is_disabled_in_ui ? styles.leverDisabled : styles.leverActive}>
                {lever.value} {lever.unit}
              </label>
            }
          </div>
        </div>
      ))}
      <h4 className={styles.footerStyling}>{COPY.CASE_DISTRIBUTION_FOOTER_ASTERISK_DESCRIPTION}</h4>
      <div className="cf-help-divider"></div>
    </div>
  );
};

BatchSize.propTypes = {
  isAdmin: PropTypes.bool.isRequired
};

export default BatchSize;
