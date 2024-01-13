import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { css } from 'glamor';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';
import NumberField from 'app/components/NumberField';
import COPY from '../../../COPY';
import { getLeversByGroup, getLeverErrors, getUserIsAcdAdmin } from '../reducers/levers/leversSelector';
import { updateNumberLever, addLeverErrors, removeLeverErrors } from '../reducers/levers/leversActions';
import { Constant } from '../constants';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';
import { validateLeverInput } from '../utils';

const BatchSize = () => {
  const theState = useSelector((state) => state);
  const isUserAcdAdmin = getUserIsAcdAdmin(theState);

  const leverNumberDiv = css({
    '& .cf-form-int-input': { width: 'auto', display: 'inline-block', position: 'relative' },
    '& .cf-form-int-input .input-container': { width: 'auto', display: 'inline-block', verticalAlign: 'middle' },
    '& .cf-form-int-input label': { position: 'absolute', bottom: '8px', left: '75px' },
    '& .usa-input-error label': { bottom: '15px', left: '89px' }
  });

  const dispatch = useDispatch();
  const batchLevers = getLeversByGroup(theState, Constant.LEVERS, ACD_LEVERS.lever_groups.batch);
  const [batchSizeLevers, setBatchSizeLevers] = useState(batchLevers);

  function leverErrors(leverItem) {
    return getLeverErrors(theState, leverItem)
  }

  useEffect(() => {
    setBatchSizeLevers(batchLevers);
  }, [batchLevers]);

  const handleValidation = (lever, leverItem, value) => {
    const validationErrors = validateLeverInput(lever, value)
    const errorExists = leverErrors(leverItem).length > 0
    if(validationErrors.length > 0 && !errorExists) {
      dispatch(addLeverErrors(validationErrors))
    }

    if (validationErrors.length === 0 && errorExists) {
      dispatch(removeLeverErrors(leverItem))
    }

  }

  const updateNumberFieldLever = (lever) => (event) => {
    const { lever_group, item } = lever
    handleValidation(lever, item, event)
    dispatch(updateNumberLever(lever_group, item, event));
  };



  batchLevers?.sort((leverA, leverB) => leverA.lever_group_order - leverB.lever_group_order);

  return (
    <div className={styles.leverContent}>
      <div className={styles.leverHead}>
        <h2>{COPY.CASE_DISTRIBUTION_BATCH_SIZE_H2_TITLE}</h2>
        <div className={styles.leverLeft}><strong>{COPY.CASE_DISTRIBUTION_BATCH_SIZE_LEVER_LEFT_TITLE}</strong></div>
        <div className={styles.leverRight}><strong>{COPY.CASE_DISTRIBUTION_BATCH_SIZE_LEVER_RIGHT_TITLE}</strong></div>
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
            {isUserAcdAdmin ?
              <NumberField
                name={lever.item}
                label={lever.unit}
                isInteger
                readOnly={lever.is_disabled_in_ui}
                value={lever.value}
                errorMessage={leverErrors(lever.item)}
                onChange={updateNumberFieldLever(lever)}
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

export default BatchSize;
