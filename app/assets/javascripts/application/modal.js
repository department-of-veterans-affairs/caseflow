//= require jquery

window.Modal = (function($) {

  window.radioValidated = true;
  window.emailValidate = true;
  var emailPattern = /^[A-Z0-9._%+-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}$/i;



  function openModal(e) {
    e.preventDefault();
    var target = $(e.target).attr("href");
    $(target).addClass("active");
  }

  function closeModal(e) {
    e.stopPropagation();
    e.stopImmediatePropagation();

    if ($(e.target).hasClass("cf-modal") || $(e.target).hasClass("cf-action-closemodal")) {
      e.preventDefault();
      $(e.currentTarget).removeClass("active");
    }
  }

  function onKeyDown(e) {
    var escKey = (e.which === 27);

    if (escKey) {
      $('.cf-modal').trigger('click');
    }
  }

  function validateQuestions(){
    const DIV = 'div';
    const SPAN = 'span';
    const FIELDSET = 'fieldset';
    const ERROR_CLASS = 'usa-input-error';

    var submitButton = $("#cancel-certification-link");
    var radioInput = $("input:radio[name='cancelation-reasons']");
    var textboxInput = $("textarea[id='other-text']");
    var emailInput = $(":root").find('#confirm-cancel-certification').find( 'input[type="text"]');

    var ERROR_MESSAGES = {};
      ERROR_MESSAGES[radioInput] = "Make sure you've selected an option bellow.";
      ERROR_MESSAGES[textboxInput] =   "Make sure you’ve filled out the comment box below.";
      ERROR_MESSAGES[emailInput] =   "Make sure you’ve entered a valid email address below.";

    function addError(element) {
              element.parent().addClass(ERROR_CLASS);
              element.prev(SPAN).text(ERROR_MESSAGES[element]);
              $(element).css("width", '46rem');
              $(element).focus();
    }

    function removeError(element) {
      element.closest(DIV).removeClass(ERROR_CLASS);
      element.prev(SPAN).empty();
    }

    function hasError(element){
      return element.closest(DIV).hasClass(ERROR_CLASS);
    }

    radioInput.click(function(event) {
              if (hasError(radioInput)) {
                radioInput.closest(DIV).removeClass(ERROR_CLASS);
                radioInput.closest(FIELDSET).prev(SPAN).empty();
                window.radioValidated = true;
              }
              if (hasError(textboxInput)) {
                removeError(textboxInput);
                window.radioValidated = true;
              }
              if($('#other-reason').is(':checked')) {
                $('#other').show();
              }
              else {
                $('#other').hide();
              }
    });

    submitButton.click(function(event) {

        checkCancelationReasons();
        checkEmail();

        function checkCancelationReasons(){
          if(radioInput.is(":checked")){
              if($('#other-reason').is(':checked')) {
                if(!textboxInput.val()){
                  addError(textboxInput);
                  window.radioValidated = false;
                }
                else{
                  if (hasError(textboxInput)) {
                    removeError(textboxInput);
                    window.radioValidated = true;
                  }
                }
              }
          }
          else{
            radioInput.closest(DIV).addClass(ERROR_CLASS);
            radioInput.closest(FIELDSET).prev(SPAN).text(ERROR_MESSAGES[radioInput]);
            window.radioValidated = false;
          }
        }

        function checkEmail(){
          if ( ! emailInput.val() || (!emailPattern.test(emailInput.val()))){
            addError(emailInput);
            window.emailValidated = false;
          }
          else {
            if (hasError(emailInput)) {
              removeError(emailInput);
              window.emailValidated = true;
            }
          }
        }

       if (!window.radioValidated || !window.emailValidated) {
            event.preventDefault();
        }
    });
  }

  // public
  return {
    bind: function() {
      $("input[name$='cancelation-reasons']").prop('checked', false);
      $('.cf-action-openmodal').on('click', openModal);
      $('.cf-modal').on('click', closeModal);
      $(window).on('keydown', onKeyDown);
      validateQuestions();
    }
  };
})($);
