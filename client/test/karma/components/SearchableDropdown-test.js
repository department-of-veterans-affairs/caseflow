import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { SearchableDropdown } from '../../../app/components/SearchableDropdown';

describe('SearchableDropdown', () => {
  it('renders nothing when the document is not found', () => {
    expect(wrapper.html()).to.equal(null);
  });

  it('renders no icons when the doc is not in any categories', () => {
    const documents = {
      3: {}
    };

    const wrapper = mount(<DocumentCategoryIcons
                              documents={documents}
                              docId={3} />);

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(0);
  });

  it('renders an icon when the doc is in category_procedural', () => {
    const documents = {
      3: {
        category_procedural: true // eslint-disable-line camelcase
      }
    };

    const wrapper = mount(<DocumentCategoryIcons
                              documents={documents}
                              docId={3} />);

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(1);
    expect(wrapper.find('.cf-document-category-icons li').
        at(0).
        prop('aria-label')
      ).
      to.equal('Procedural');
  });