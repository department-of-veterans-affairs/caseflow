import React, { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { css } from 'glamor';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';
import NumberField from 'app/components/NumberField';
import COPY from '../../../COPY';
import ACD_LEVERS from '../../../constants/ACD_LEVERS'
import { getUserIsAcdAdmin, getLeversByGroup } from '../reducers/levers/leversSelector';
import { updateLeverState } from '../reducers/levers/leversActions';

const BatchSize = () => {
  const leverNumberDiv = css({
    '& .cf-form-int-input': { width: 'auto', display: 'inline-block', position: 'relative' },
    '& .cf-form-int-input .input-container': { width: 'auto', display: 'inline-block', verticalAlign: 'middle' },
    '& .cf-form-int-input label': { position: 'absolute', bottom: '8px', left: '75px' },
    '& .usa-input-error label': { bottom: '15px', left: '89px' }
  });

  const errorMessages = {};
  const dispatch = useDispatch();
  const theState = useSelector((state) => state);
  const storeLevers = getLeversByGroup(theState, ACD_LEVERS.LEVERS, ACD_LEVERS.BATCH);
  const isUserAcdAdmin = getUserIsAcdAdmin(theState);
  const [errorMessagesList] = useState(errorMessages);
  const [batchSizeLevers, setBatchSizeLevers] = useState(storeLevers);

  useEffect(() => {
    setBatchSizeLevers(storeLevers);
  }, [storeLevers]);

  const updateLever = (leverItem) => (event) => {
    dispatch(updateLeverState(ACD_LEVERS.BATCH, leverItem, event));
  };

  if (isUserAcdAdmin) {
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

              <NumberField
                name={lever.item}
                label={lever.unit}
                isInteger
                readOnly={lever.is_disabled_in_ui}
                value={lever.value}
                errorMessage={errorMessagesList[lever.item]}
                onChange={updateLever(lever.item)}
                tabIndex={lever.is_disabled_in_ui ? -1 : null}
              />
              {!lever.is_disabled_in_ui && (
                <label className={styles.leverActive}>
                  {lever.value} {lever.unit}
                </label>
              )}

            </div>
          </div>
        ))}
        <h4 className={styles.footerStyling}>{COPY.CASE_DISTRIBUTION_FOOTER_ASTERISK_DESCRIPTION}</h4>
        <div className="cf-help-divider"></div>
      </div>
    );
  }
};

export default BatchSize;
