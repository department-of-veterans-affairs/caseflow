---
nav_order: 1
permalink: "index"
nav_exclude: true
---

# Contents

<p>
  <button class="btn js-toggle-dark-mode">Preview dark theme</button>
  <script>
    const toggleDarkMode = document.querySelector('.js-toggle-dark-mode');
    jtd.addEvent(toggleDarkMode, 'click', function() {
      if (jtd.getTheme() === 'dark') {
        jtd.setTheme('light');
        toggleDarkMode.textContent = 'Preview dark theme';
      } else {
        jtd.setTheme('dark');
        toggleDarkMode.textContent = 'Return to the light side';
      }
    });
  </script>
</p>

## Database
* [Caseflow DB schema](schema/index.html) (created via [Jailer](https://github.com/Wisser/Jailer))

