import React from 'react';
import PropTypes from 'prop-types';

const VirtualHearingLink = (props) => {
  if (!props.hearing.isVirtual) {
    return null;
  }

  return (<div>
    <a href={`https://care.evn.va.gov/webapp/?conference=${props.hearing.virtualHearing.alias}
    &pin=${props.hearing.virtualHearing.pin}&join=1&role=${props.hearing.virtualHearing.role}`}
    target={props.newWindow ? '_blank' : '_self'}>
      <strong>Virtual Hearing Link</strong>
    </a>
  </div>);
};

VirtualHearingLink.propTypes = {
  newWindow: PropTypes.bool,
  hearing: PropTypes.shape({
    virtualHearing: PropTypes.shape({
      address: PropTypes.object,
      guest_pin: PropTypes.number,
      host_pin: PropTypes.number,
      pin: PropTypes.number,
      alias: PropTypes.string,
      role: PropTypes.string
    }),
    isVirtual: PropTypes.bool
  })
};

export default VirtualHearingLink;
