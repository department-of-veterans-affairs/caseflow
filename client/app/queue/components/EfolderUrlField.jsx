import React, { useEffect, useState, useRef } from 'react';
import PropTypes from 'prop-types';
import { debounce } from 'lodash';

import COPY from '../../../COPY';
import Button from '../../components/Button';
import TextField from '../../components/TextField';
import ApiUtil from '../../util/ApiUtil';

const EfolderUrlField = (props) => {

  const [url, setUrl] = useState('');
  const [valid, setValid] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const valueRef = useRef(url);

  const extractRequestType = () => (
    props.requestType.replace('Hearing', '').replace('RequestMailTask', '').
      toLowerCase()
  );

  const efolderLinkRegexMatch = (inputValue) => {
    return inputValue.match(/https:\/\/vefs-claimevidence.*\.bip\.va\.gov\/file\/\S{8}-\S{4}-\S{4}-\S{4}-\S{12}/)?.[0] === inputValue.split('?')[0]; // eslint-disable-line
  };

  const captureDocumentSeriesId = (validUrl) => {
    return validUrl.match(/\S{8}-\S{4}-\S{4}-\S{4}-\S{12}/)?.[0];
  };

  const checkIfDocumentExists = async () => {
    setLoading(true);
    const seriesId = captureDocumentSeriesId(url);
    const appealId = props.appealId;

    let apiValidity = false;

    await ApiUtil.get(`/appeals/${appealId}/document/${seriesId}`).
      then((response) => {
        if (response.body.document_presence === true) {
          apiValidity = true;
          // setValid(true);
          setError('');
        } else {
          apiValidity = false;
          setValid(false);
          setError(COPY.EFOLDER_DOCUMENT_NOT_FOUND);
        }
      }).
      catch(() => {
        apiValidity = false;
        // setValid(false);
        setError(COPY.EFOLDER_CONNECTION_ERROR);
      }).
      finally(() => {
        setLoading(false);
      });

    return apiValidity;
  };

  const handleDebounce = debounce(async (value) => {
    if (valueRef.current === value) {
      props?.onChange?.(url, valid);

      return;
    }

    let newValidity;

    if (efolderLinkRegexMatch(value)) {
      newValidity = await checkIfDocumentExists();
    } else {
      newValidity = false;
      setError(COPY.EFOLDER_INVALID_LINK_FORMAT);
    }
    valueRef.current = value;
    props?.onChange?.(url, newValidity);
    setValid(newValidity);
  }, 500);

  useEffect(() => {
    props?.onChange?.(url, false);
    handleDebounce(url);

    return () => {
      handleDebounce.cancel();
    };
  }, [url, valid]);

  return <>
    <TextField
      label={`Include eFolder document hyperlink to request a hearing ${extractRequestType()}`}
      name="eFolderUrlField"
      value={url}
      onChange={(newUrl) => setUrl(newUrl)}
      errorMessage={error}
      loading={loading}
    />

    {
      error === COPY.EFOLDER_CONNECTION_ERROR &&
      <Button
        onClick={() => checkIfDocumentExists()}
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
