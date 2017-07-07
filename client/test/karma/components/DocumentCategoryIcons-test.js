import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { DocumentCategoryIcons } from '../../../app/components/DocumentCategoryIcons';

describe('DocumentCategoryIcons', () => {
  it('renders no icons when the doc is not in any categories', () => {
    const wrapper = mount(<DocumentCategoryIcons doc={{}} />);
    console.log(wrapper.html());
    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(0);
  });

  it('renders an icon when the doc is in category_procedural', () => {
    const doc = {
      category_procedural: true // eslint-disable-line camelcase
    };

    const wrapper = mount(<DocumentCategoryIcons doc={doc} />);

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(1);
    expect(wrapper.find('.cf-document-category-icons li').
        at(0).
        prop('aria-label')
      ).
      to.equal('Procedural');
  });

  it('renders an icon when the doc is in category_other', () => {
    const doc = {
      category_other: true // eslint-disable-line camelcase
    };

    const wrapper = mount(<DocumentCategoryIcons doc={doc} />);

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(1);
    expect(wrapper.find('.cf-document-category-icons li').
        at(0).
        prop('aria-label')
      ).
      to.equal('Other Evidence');
  });

  it('renders an icon when the doc is in category_medical', () => {
    const doc = {
      category_medical: true // eslint-disable-line camelcase
    };

    const wrapper = mount(<DocumentCategoryIcons doc={doc} />);

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(1);
    expect(wrapper.find('.cf-document-category-icons li').
        at(0).
        prop('aria-label')
      ).
      to.equal('Medical');
  });

  it('renders three icons when the doc is in all categories', () => {
    const doc = {
      category_medical: true, // eslint-disable-line camelcase
      category_procedural: true, // eslint-disable-line camelcase
      category_other: true // eslint-disable-line camelcase
    };

    const wrapper = mount(<DocumentCategoryIcons doc={doc} />);

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(3);
  });
});
