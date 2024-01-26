import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import cx from 'classnames';
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

  const dispatch = useDispatch();
  const batchLevers = getLeversByGroup(theState, Constant.LEVERS, ACD_LEVERS.lever_groups.batch);
  const [batchSizeLevers, setBatchSizeLevers] = useState(batchLevers);

  const leverErrors = (leverItem) => {
    return getLeverErrors(theState, leverItem);
  };

  useEffect(() => {
    setBatchSizeLevers(batchLevers);
  }, [batchLevers]);

  const handleValidation = (lever, leverItem, value) => {
    const validationErrors = validateLeverInput(lever, value);
    const errorExists = leverErrors(leverItem).length > 0;

    if (validationErrors.length > 0 && !errorExists) {
      dispatch(addLeverErrors(validationErrors));
    }

    if (validationErrors.length === 0 && errorExists) {
      dispatch(removeLeverErrors(leverItem));
    }

  };

  const updateNumberFieldLever = (lever) => (event) => {
    // eslint-disable-next-line camelcase
    const { lever_group, item } = lever;

    handleValidation(lever, item, event);
    dispatch(updateNumberLever(lever_group, item, event));
  };

  return (
    <div className="lever-content">
      <div className="lever-head">
        <h2>{COPY.CASE_DISTRIBUTION_BATCH_SIZE_H2_TITLE}</h2>
        <div className="lever-left"><strong>{COPY.CASE_DISTRIBUTION_BATCH_SIZE_LEVER_LEFT_TITLE}</strong></div>
        <div className="lever-right"><strong>{COPY.CASE_DISTRIBUTION_BATCH_SIZE_LEVER_RIGHT_TITLE}</strong></div>
      </div>
      {batchSizeLevers && batchSizeLevers.map((lever, index) => (
        <div className="active-lever" key={`${lever.item}-${index}`}>
          <div className="lever-left">
            <strong className={lever.is_disabled_in_ui ? 'lever-disabled' : 'lever-active'}>
              {lever.title}
            </strong>
            <p className={lever.is_disabled_in_ui ? 'lever-disabled' : 'lever-active'}>
              {lever.description}
            </p>
          </div>
          <div className={cx('lever-right', 'batch-lever-num-sec')} aria-label={`${lever.title} ${lever.description}`}>
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
                id={`${lever.item}-field`}
                disabled={lever.is_disabled_in_ui}
              /> :
              <label className={lever.is_disabled_in_ui ? 'lever-disabled' : 'lever-active'}>
                {lever.value} {lever.unit}
              </label>
            }
          </div>
        </div>
      ))}
      <h4 className="footer-styling">{COPY.CASE_DISTRIBUTION_FOOTER_ASTERISK_DESCRIPTION}</h4>
      <div className="cf-help-divider"></div>
    </div>
  );
};

export default BatchSize;
