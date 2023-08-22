import React, { useEffect, useState, useRef } from 'react';
import PropTypes from 'prop-types';
import { debounce } from 'lodash';

import COPY from '../../../COPY';
import Button from '../../components/Button';
import TextField from '../../components/TextField';
import ApiUtil from '../../util/ApiUtil';

const EfolderUrlField = (props) => {

  const [valid, setValid] = useState(false);
  const [loading, setloading] = useState(false);
  const [error, setError] = useState('');
  const valueRef = useRef(props.value);

  const extractRequestType = () => (
    props.requestType.replace('Hearing', '').replace('RequestMailTask', '').
      toLowerCase()
  );

  const efolderLinkRegexMatch = (url) => {
    return url.match(/https:\/\/vefs-claimevidence.*\.bip\.va\.gov\/file\/\S{8}-\S{4}-\S{4}-\S{4}-\S{12}/)?.[0] === url.split('?')[0];
  };

  const captureDocumentSeriesId = (url) => {
    return url.match(/\S{8}-\S{4}-\S{4}-\S{4}-\S{12}/)?.[0];
  };

  const handleChange = (value) => {
    props?.onChange?.(value, valid);
  };

  const handleDebounce = debounce((value) => {

    if (valueRef.current === value) {
      handleChange(props.value);

      return;
    }

    if (efolderLinkRegexMatch(value)) {
      setloading(true);
      const seriesId = captureDocumentSeriesId(value);
      const appealId = props.appealId;

      ApiUtil.get(`/appeals/${appealId}/document/${seriesId}`).
        then((response) => {
          if (response.body.document_presence === true) {
            setValid(true);
            setError('');
          } else {
            setValid(false);
            setError(COPY.EFOLDER_DOCUMENT_NOT_FOUND);
          }
        }).
        catch(() => {
          setValid(false);
          setError(COPY.EFOLDER_CONNECTION_ERROR);
        }).
        finally(() => {
          setloading(false);
        });
    } else {
      setValid(false);
      setError(COPY.EFOLDER_INVALID_LINK_FORMAT);
    }
    valueRef.current = value;
    handleChange(props.value);
  }, 500);

  useEffect(() => {
    handleDebounce(props.value);

    return () => {
      handleDebounce.cancel();
    };
  }, [props.value, valid]);

  return <>
    <TextField
      label={`Include eFolder document hyperlink to request a hearing ${extractRequestType()}`}
      name="eFolderUrlField"
      value={props.value}
      onChange={handleChange}
      errorMessage={error}
      loading={loading}
    />

    {
      error === COPY.EFOLDER_CONNECTION_ERROR &&
      <Button
        onClick={() => handleDebounce(props.value)}
        linkStyling
        classNames={['cf-push-right', 'cf-retry']}>
          Retry
      </Button>
    }
  </>;
};

EfolderUrlField.propTypes = {
  appealId: PropTypes.string.isRequired,
  requestType: PropTypes.string,
  value: PropTypes.string,
  errorMessage: PropTypes.string,
  valid: PropTypes.bool
};

export default EfolderUrlField;
