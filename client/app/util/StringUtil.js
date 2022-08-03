import { capitalize, words, map } from 'lodash';
import React from 'react';
import DOMPurify from 'dompurify';

const StringUtil = {
  camelCaseToDashCase(variable) {
    // convert key from camelCase to dash-case
    return variable.replace(/([A-Z])/g, ($1) => `-${$1.toLowerCase()}`);
  },

  camelCaseToSnakeCase(variable) {
    // convert key from camelCase to snake_case
    if (!variable) {
      return variable;
    }

    return variable.replace(/([A-Z])/g, ($1) => `_${$1.toLowerCase()}`);
  },

  // Converts regular language to camelCase
  // 'VACOLS - 123, User' becomes 'vacolsUser'
  convertToCamelCase(phrase = '') {
    // Code courtesy of Stack Overflow, Question 2970525
    return phrase.
      toLowerCase().
      replace(/[^a-zA-Z ]/g, '').
      replace(/(?:^\w|[A-Z]|\b\w|\s+)/g, (match, index) => {
        if (Number(match) === 0) {
          return '';
        }

        return index === 0 ? match.toLowerCase() : match.toUpperCase();
      });
  },

  capitalizeFirst(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
  },

  leftPad(string, width, padding = '0') {
    let padded = '';

    for (let i = 0; i < width; i++) {
      padded += padding;
    }

    return (padded + string).slice(-width);
  },

  titleCase(string) {
    return map(words(string), capitalize).join(' ');
  },

  // https://coderwall.com/p/iprsng/convert-snake-case-to-camelcase
  snakeCaseToCamelCase(variable = '') {
    // convert key from camelCase to snake_case
    return variable?.replace(/(_\w)/g, (found) => found[1].toUpperCase()) ?? '';
  },

  // convert snake_case to Capitalized Words
  snakeCaseToCapitalized(variable = '') {
    return (
      variable
        ?.replace(/_/g, ' ')
        .split(' ')
        .map((word) => {
          return word[0].toUpperCase() + word.substr(1);
        })
        .join(' ') ?? ''
    );
  },

  // convert snake_case to a sentence with the first letter capitalized
  snakeCaseToSentence(variable) {
    const sentence = variable.replace(/_/g, ' ');

    return sentence[0].toUpperCase() + sentence.substring(1);
  },

  html5CompliantId(str) {
    return str.replace(/[^A-Za-z0-9-]/g, '-').replace(/-+/g, '-');
  },

  // convert (Capitalized) Words to lowercase, snake_case, remove punctuation
  parameterize(str) {
    return str.toLowerCase().replace(/\W+/g, '_');
  },

  /**
   * Parses an input string to wrap URLs in HTML anchor tags
   * @param {string} str input string
   * @param {object} options allows setting of target
   */
  parseLinks(str = '', { target = '_blank' } = {}) {
    // Original regex from https://code.tutsplus.com/tutorials/8-regular-expressions-you-should-know--net-6149
    // Modified by @nanotone to better deal with whitespace:
    // https://github.com/department-of-veterans-affairs/caseflow/pull/14788
    // eslint-disable-next-line
    const regex = /(https?:\/\/|\b)[-\da-z.]+\.[a-z]{2,6}\/\S*/gi;

    // Add anchor tags
    const replaced = str.replace(regex, `<a href="$&" ${target ? `target="${target}"` : ''}>$&</a>`);

    // Sanitize, but ensure we allow `target` attribute
    return DOMPurify.sanitize(replaced, {
      ADD_ATTR: ['target']
    });
  },

  // Replace newline ("\n") characters with React-friendly <br /> elements
  nl2br(str) {
    if (typeof str !== 'string') {
      return str;
    }

    const arr = str.split(/\r\n|\r|\n/g);

    return arr.map((txt, idx) => {
      return (
        <React.Fragment key={idx}>
          {txt}
          {idx < arr.length - 1 ? <br /> : null}
        </React.Fragment>
      );
    });
  },

  // Removes **Details** from previous tasks' instructions from markdown text
  // used within Case Timelines
  removeInstructionsDetails(str) {
    return str.split('**Detail')[0];
  }
};

export default StringUtil;
