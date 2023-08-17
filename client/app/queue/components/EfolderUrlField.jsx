import React, { useEffect, useState, useRef } from 'react';
import PropTypes from 'prop-types';
import { debounce } from 'lodash';

import TextField from '../../components/TextField';
import ApiUtil from '../../util/ApiUtil';

const EfolderUrlField = (props) => {

  const [valid, setValid] = useState(false);
  const [loading, setloading] = useState(false);
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
    console.log('Debounced!');

    if (valueRef.current === value) {
      handleChange(props.value);

      return;
    }

    if (efolderLinkRegexMatch(value)) {
      console.log('Valid regex match, spinner on');
      // start loading spinner
      setloading(true);
      const seriesId = captureDocumentSeriesId(value);
      const appealId = props.appealId;

      ApiUtil.get(`/appeals/${appealId}/document/${seriesId}`).
        then((response) => {
          if (response.body.document_presence === true) {
            setValid(true);
          } else {
            setValid(false);
            // show error message
          }
          console.log('Response received')
        }).
        catch((response) => {
          // handle errors
        }).
        finally(() => {
          console.log('loading spinner off')
          setloading(false);
        });
    } else {
      console.log('Invalid efolder regex match');
      setValid(false);
      // https://benefits-int-delivery.slack.com/archives/C03NCPYRXK2/p1687881917481399?thread_ts=1687878651.089549&cid=C03NCPYRXK2
      // Show error message as described in thread ^^ (invalid link format)
      // Block form submission until resolved
    }
    valueRef.current = value
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
      label={`Include Caseflow Reader document hyperlink to request a hearing ${extractRequestType()}`}
      name="eFolderUrlField"
      value={props.value}
      onChange={handleChange}
      errorMessage={props.errorMessage}
      loading={loading}
    />
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
