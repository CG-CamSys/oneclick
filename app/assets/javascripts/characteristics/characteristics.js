/**
 * Created by Miguel Bermudez on 12/9/13.
 */

var dobFirst;
var characteristicsView = {
  indexCounter: 0,
  dobView: false,
  formItems: [],
  dobItems: [],
  states: {
    YESNO: 0,
    QUESTIONS: 1,
    DOB: 2,
    PROGRAMS: 3,
    TRAVELTIME: 4,
    PURPOSE: 5,
    RETURN: 6,
    RETURNTIME: 7,
    OVERVIEW: 8
  }
};

characteristicsView.init = function () {
  "use strict";

  //cache all form items
  this.formItems = $('*[data-index]');
  this.formItems.addClass('hidden');
  this.dobItems = $('.dob-section', '#new_user_characteristics_proxy');
  this.dob = {
    counter: 0,
    states: {
      MONTH: 0,
      DAY: 1,
      YEAR: 2
    },
    params: {},
    breadcrumbs: $('.dob-breadcrumb li'),
    monthtable: $('#monthtable'),
    daytable: $('#daytable'),
    yeartable: $('#yeartable'),
    yearlist: $('#yearlist'),

    //get number of days for a particular month, months are 0 based
    numberOfDays: function(month) {
      var now = new Date();
      var m = month + 1;
      var d = new Date(now.getUTCFullYear(), m, 0);
      return d.getDate();
    }
  };

  //add indexChange handler to form
  $('#eligibility_form').on('indexChange', characteristicsView.indexChangeHandler);

  //add click handler to next button
  $('.next-step-btn, a#yes').on('click', characteristicsView.nextBtnHandler);

  //add click handlers to dob form li elements (table)
  characteristicsView.dobItems.find('li').on('click', characteristicsView.handleDobElemClick);




  //reveal first form item
  $('div[data-index="0"]').removeClass('hidden');

  $('input[name="user_characteristics_proxy[disabled]"]:radio').on('change', function (event) {
    $.ajax({
      url    : 'header',
      data   : {state: event.currentTarget.id},
      success: function (result) {
        $('#characteristics_header').html(result);
      }
    });
  });
};

characteristicsView.nextBtnHandler = function () {

  //if we're on the last dob form item, switch dobview flag to adv to next
  //characteristic form item
  if (characteristicsView.dob.counter >= characteristicsView.dob.states.YEAR) {
    characteristicsView.dobView = false;
  }

  //if we're in the dob section, don't increment the index
  if (characteristicsView.dobView === false) {
    //increment counter
    characteristicsView.indexCounter++;
  }
  else {
    //increment the dob counter
    characteristicsView.dob.counter++;
  }

  //trigger counter change event
  $('#eligibility_form').trigger('indexChange');
};

characteristicsView.indexChangeHandler = function () {
  //hide everything again
  if (characteristicsView.indexCounter != characteristicsView.states.PROGRAMS) {
    characteristicsView.formItems.addClass('hidden');
  }

  //hide all dob form items
  characteristicsView.dobItems.addClass('hidden');

  //remove current class from dob breadcrumbs
  characteristicsView.dob.breadcrumbs.removeClass('current');

  //find element matching current index and dob index
  var matchedElement = $('div[data-index="' + characteristicsView.indexCounter + '"]');
  var matchedDOBElement = $('div[data-dobindex="' + characteristicsView.dob.counter+ '"]');

  //set current dob breadcrumb
  $(characteristicsView.dob.breadcrumbs[characteristicsView.dob.counter]).addClass('current');

  //matched element visible
  matchedElement.removeClass('hidden');
  matchedDOBElement.removeClass('hidden');

  if (characteristicsView.dobView === false) {
    switch(characteristicsView.indexCounter) {
      case characteristicsView.states.QUESTIONS:
        $('div.next-footer-container').removeClass('hidden');
        break;

      case characteristicsView.states.DOB:
        // get month from previous dob form item or if there was a problem,
        // create the current month
        characteristicsView.dob.params.month = characteristicsView.dob.params.month || new Date().getMonth();
        var month = characteristicsView.dob.params.month;

        //setup initial ul template
        var dobDaysTemplate = $('<ul>');

        //flag we're in the dob section
        characteristicsView.dobView = true;

        //populate dob days view
        //  convert num of days into range array
        var dayArray = CGUtils.range( 1, (characteristicsView.dob.numberOfDays(month) + 1) );
        $.each(dayArray, function(index, day) {
          var liElem;
          var numberOfDaysInRow = 8;

          //check if current iteration is last row
          var lastRow = ((index+1) % dayArray.length === 0);

          if ( index >= Math.floor(dayArray.length/numberOfDaysInRow) * numberOfDaysInRow) {
            liElem = $('<li>').addClass('bottom').text(day);
          } else {
            liElem = $('<li>').text(day);
          }

          //atached li elem to current ul elem
          dobDaysTemplate.append(liElem);

          if( ((index+1) % numberOfDaysInRow === 0) || lastRow ) {
            characteristicsView.dob.daytable.append(dobDaysTemplate);
            //reset ul elem
            dobDaysTemplate = $('<ul>');
          }
        });

        //attach template to view
        //characteristicsView.dob.daytable.append(dobDaysTemplate);
        break;

      case characteristicsView.states.PROGRAMS:
        $('#new_user_characteristics_proxy').submit();
        break;
    }
  }
};

characteristicsView.handleDobElemClick = function(e) {
  var $target = $(e.target);
  var value = $target.val();

  //set dob params on li elem click
  switch ($target.attr('data-dobindex')) {
    case characteristicsView.dob.states.MONTH:
      characteristicsView.dob.params.month = value;
      break;
    case characteristicsView.dob.states.DAY:
      characteristicsView.dob.params.day = value;
      break;
    case characteristicsView.dob.states.YEAR:
      characteristicsView.dob.params.year = value;
      break;
  }
};


$(document).ready(function () {
  "use strict";

  $('#monthtable ul li').on('click', function () {
    dobFirst = $(this);
    $('#monthtable ul li').removeClass('selected');
    dobFirst.addClass('selected');
    $('.dob-breadcrumb li.month span.input').text(dobFirst.html());
    $('li.month span.type').addClass('val-added');
    $('#monthtable').fadeOut(function () {
      $('#daytable').fadeIn().removeClass('hidden');
      $('.dob-breadcrumb li.month').toggleClass('current chosen');
      $('.dob-breadcrumb li.day').addClass('current');
    });
  });

  //kick everything off
  characteristicsView.init();

});

window.CGUtils = {
  // Underscore _.range() method
  // src: http://underscorejs.org/#range
  range: function(start, stop, step) {
    if (arguments.length <= 1) {
      stop = start || 0;
      start = 0;
    }
    step = arguments[2] || 1;

    var length = Math.max(Math.ceil((stop - start) / step), 0);
    var idx = 0;
    var range = new Array(length);

    while(idx < length) {
      range[idx++] = start;
      start += step;
    }

    return range;
  }
}
