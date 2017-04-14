import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import SignAndCertify from '../../app/certification/SignAndCertify';

describe('SignAndCertify', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(<SignAndCertify
      certifyingOffice="DSVA"
      certifyingUsername="Ari"
      certificationDate="2007-01-01"/>);
  });
});
