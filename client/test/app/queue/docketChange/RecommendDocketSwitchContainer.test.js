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
        new RegExp(`\\*\\*Summary:\\*\\* ${summary}<br><br>`)
      );
      expect(res).toMatch(
        new RegExp('\\*\\*Is this a timely request:\\*\\* Yes<br><br>')
      );
      expect(res).toMatch(
        new RegExp('\\*\\*Recommendation:\\*\\* Grant all issues<br><br>')
      );
      expect(res).toMatch(new RegExp(`\\*\\*Draft letter:\\*\\* ${hyperlink}`));
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
        new RegExp(`\\*\\*Summary:\\*\\* ${summary}<br><br>`)
      );
      expect(res).toMatch(
        new RegExp('\\*\\*Is this a timely request:\\*\\* Yes<br><br>')
      );
      expect(res).toMatch(
        new RegExp(
          '\\*\\*Recommendation:\\*\\* Grant partial docket switch<br><br>'
        )
      );
      expect(res).toMatch(new RegExp(`\\*\\*Draft letter:\\*\\* ${hyperlink}`));
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
        new RegExp(`\\*\\*Summary:\\*\\* ${summary}<br><br>`)
      );
      expect(res).toMatch(
        new RegExp('\\*\\*Is this a timely request:\\*\\* Yes<br><br>')
      );
      expect(res).toMatch(
        new RegExp('\\*\\*Recommendation:\\*\\* Deny all issues<br><br>')
      );
      expect(res).toMatch(new RegExp(`\\*\\*Draft letter:\\*\\* ${hyperlink}`));
      expect(res).toMatchSnapshot();
    });
  });
});
