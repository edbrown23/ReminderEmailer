$(document).ready(function() {
  $('#calendar').fullCalendar({
    dayClick: function(date, allDay, jsEvent, view) {
      alert(date + ' has been clicked!');
    },
    eventClick: function(event, jsEvent, view) {
      alert(event + ' has been clicked!');
    },
    eventDrop: function(event, dayDelta, minuteDelta, allDay, revertFunc, jsEvent, ui, view) {

    }
  })

  $('.date_picker_field').datetimepicker();
});
