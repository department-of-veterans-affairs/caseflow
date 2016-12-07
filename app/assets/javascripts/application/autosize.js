// Finds all textareas with the attribute "autoresize"
// and ensures that they grow vertically with the number
// of lines of user input.
//
// Credit:
// https://maximilianhoffmann.com/posts/autoresizing-textareas
// (Partially modified because the script as written scrolled
// undesirably)
//
// TODO(alex): refactor this out into caseflow-commons if & when
// we decide we want to use it elsewhere.
(function(){
  window.autoresize = {
    init: function() {
      var resizingTextareas = [].slice.call(document.querySelectorAll('textarea[autoresize]'));
      resizingTextareas.forEach(function(textarea) {
        textarea.addEventListener('input', autoresize, false);
      });
    }
  };

  function autoresize() {
    this.style.height = 'auto';
    this.style.height = this.scrollHeight + 'px';
    this.scrollTop = this.scrollHeight;
  }
})()
