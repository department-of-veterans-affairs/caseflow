import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import DocumentCategoryIcons from '../../../app/components/DocumentCategoryIcons';
import * as Constants from '../../../app/reader/constants';
import _ from 'lodash';

describe('DocumentCategoryIcons', () => {
  it('renders nothing when there are no categories', () => {
    const wrapper = mount(<DocumentCategoryIcons categories={[]} />);

    expect(wrapper.html()).to.equal(null);
  });

  it('renders an icon when the doc is in category_procedural', () => {
    const wrapper = mount(<DocumentCategoryIcons categories={[Constants.documentCategories.procedural]} />);

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(1);
    expect(wrapper.find('.cf-document-category-icons li').
        at(0).
        prop('aria-label')
      ).
      to.equal('Procedural');
  });

  it('renders an icon when the doc is in category_other', () => {
    const wrapper = mount(<DocumentCategoryIcons categories={[Constants.documentCategories.other]} />);

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(1);
    expect(wrapper.find('.cf-document-category-icons li').
        at(0).
        prop('aria-label')
      ).
      to.equal('Other Evidence');
  });

  it('renders an icon when the doc is in category_medical', () => {
    const wrapper = mount(<DocumentCategoryIcons categories={[Constants.documentCategories.medical]} />);

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(1);
    expect(wrapper.find('.cf-document-category-icons li').
        at(0).
        prop('aria-label')
      ).
      to.equal('Medical');
  });

  it('renders three icons when the doc is in all categories', () => {
    const wrapper = mount(<DocumentCategoryIcons categories={_.values(Constants.documentCategories)} />);

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(3);
  });
});
