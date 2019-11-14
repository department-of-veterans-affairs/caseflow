import React from 'react';
import PropTypes from 'prop-types';

const VirtualHearingLink = (props) =>
  <div >
    <a href={`https://care.evn.va.gov/webapp/?conference=${props.hearing.alias}&pin=${props.hearing.pin}&join=1&role=${props.hearing.role}`} target={props.newWindow ? '_blank' : '_self'}>
      {/* <i className="fa fa-inbox" ariaHidden="true"></i> */}
      <strong>VLJ Virtual Hearing Link!</strong>
    </a>
    {console.log('clicked', props.role)}
  </div>;

VirtualHearingLink.propTypes = {
  address: PropTypes.object,
  guest_pin: PropTypes.number,
  host_pin: PropTypes.number,
  pin: PropTypes.number,
  alias: PropTypes.string,
  role: PropTypes.string,
  hearing: PropTypes.object,
  virtualHearing: PropTypes.object
};

export default VirtualHearingLink;
