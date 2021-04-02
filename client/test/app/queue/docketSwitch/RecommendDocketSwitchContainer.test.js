import { formatDocketSwitchRecommendation } from 'app/queue/docketSwitch/recommendDocketSwitch/RecommendDocketSwitchContainer';

describe('formatDocketSwitchRecommendation', () => {
  const summary = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit...';
  let timely = 'yes';
  const hyperlink = 'https://example.com/file.txt';

  let disposition = 'granted';

  describe('with granted disposition', () => {
    beforeAll(() => {
      disposition = 'granted';
    });

    it('properly formats', () => {
      const res = formatDocketSwitchRecommendation({
        summary,
        timely,
        hyperlink,
        disposition,
      });

      expect(res).toMatch(
        new RegExp(`\\*\\*Summary:\\*\\* ${summary} {2}\\n {2}\\n`)
      );
      expect(res).toMatch(
        new RegExp('\\*\\*Is this a timely request:\\*\\* Yes {2}\\n {2}\\n')
      );
      expect(res).toMatch(
        new RegExp('\\*\\*Recommendation:\\*\\* Grant all issues {2}\\n {2}\\n')
      );
      expect(res).toMatch(`**Draft letter:** [View link](${hyperlink})`);
      expect(res).toMatchSnapshot();
    });
  });

  describe('with partially_granted disposition', () => {
    beforeAll(() => {
      disposition = 'partially_granted';
    });

    it('properly formats', () => {
      const res = formatDocketSwitchRecommendation({
        summary,
        timely,
        hyperlink,
        disposition,
      });

      expect(res).toMatch(
        new RegExp(`\\*\\*Summary:\\*\\* ${summary} {2}\\n {2}\\n`)
      );
      expect(res).toMatch(
        new RegExp('\\*\\*Is this a timely request:\\*\\* Yes {2}\\n {2}\\n')
      );
      expect(res).toMatch(
        new RegExp(
          '\\*\\*Recommendation:\\*\\* Grant a partial switch {2}\\n {2}\\n'
        )
      );
      expect(res).toMatch(`**Draft letter:** [View link](${hyperlink})`);
      expect(res).toMatchSnapshot();
    });
  });

  describe('with denied disposition', () => {
    beforeAll(() => {
      disposition = 'denied';
    });

    it('properly formats', () => {
      const res = formatDocketSwitchRecommendation({
        summary,
        timely,
        hyperlink,
        disposition,
      });

      expect(res).toMatch(
        new RegExp(`\\*\\*Summary:\\*\\* ${summary} {2}\\n {2}\\n`)
      );
      expect(res).toMatch(
        new RegExp('\\*\\*Is this a timely request:\\*\\* Yes {2}\\n {2}\\n')
      );
      expect(res).toMatch(
        new RegExp('\\*\\*Recommendation:\\*\\* Deny all issues {2}\\n {2}\\n')
      );
      expect(res).toMatch(`**Draft letter:** [View link](${hyperlink})`);
      expect(res).toMatchSnapshot();
    });
  });
});

