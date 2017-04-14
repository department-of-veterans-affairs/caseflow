import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { DocumentCategoryIcons } from '../../app/components/DocumentCategoryIcons';

describe('DocumentCategoryIcons', () => {
  it('renders no icons when the doc is not in any categories', () => {
    const documents = {
      3: {}
    };

    const wrapper = mount(<DocumentCategoryIcons
                              documents={documents}
                              id={3} />);

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
                              id={3} />);

    console.log(wrapper.html());

    expect(wrapper.find('.cf-document-category-icons li')).to.have.length(1);
    expect(wrapper.find('.cf-document-category-icons li').get(0).ariaLabel).
      to.equal('Procedural');
  });
});
