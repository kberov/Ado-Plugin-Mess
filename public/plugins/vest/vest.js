//vest.js - Browser-side functionality for Ado::Plugin::Vest
(function($) {
  //https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Strict_mode
  'use strict';
  // Functionality related to talks
  // Object used to store various data
  var VestTalk = {
    json_messages: {
      data: []
    }
  };
  $(document).ready(function($) {
    //Initialize the left sidebar
    $('#talks').sidebar();
    $('#talks_button').click(function() {
      $('#talks').sidebar('toggle');
    });
    //Initializing the right sidebar is done in contacts.html.ep until
    //I realize why it is not working if code is here.

    // Fill in #messages with the last talk and
    // bind onclick to filling-in messages in the #messages
    $('#talks ul li a').click(get_messages);
    // List messages from the last talk.
    $('#talks ul li a:first').click();
    $(window).blur(stop_polling);
    $(window).focus(start_polling);

    $('#contacts .list .item').click(new_talk);
    // To send or not to send the message?
    $('#message_form').submit(validate_and_send_message);
    // Send message by pressing Enter.
    $('#message_form [name="message"]').keydown(function(e){
      if ( (!e.ctrlKey && !e.shiftKey ) && e.which == 13 ){
        $('#message_form').submit();
      }
    });
  }); // end $(document).ready(function($)

  /**
   * Gets last 20 messages from a talk.
   * Performs a GET request to the url found in the 'href' attribute
   * of a talk item and invokes list_messages_from_json() to populate the
   * #messages box.
   * @return bool false - to prevent the default behaviour of the 'a' tag.
   */
  function get_messages(e) {
    var link = e.target;
    // close the sidebar
    $('#talks').sidebar('hide');

    // get the messages
    $.get(link.href, list_messages_from_json);
    return false;
  }

  /**
   * Populates in #mesages list box with the messages found in
   * the received json.
   */
  function list_messages_from_json(json_messages) {
    var messages = $('#messages .ui.list');
    messages.html('');
    //Save it for later use by validate_and_send_message
    VestTalk.json_messages = json_messages;
    //
    //console.log(json_messages);
    var prev_msg = {};
    $(json_messages.data).each(function(i, msg) {

      // This is the message defining the topic (the parent message).
      if (msg.subject_message_id === 0) {
        set_talk_form(msg); // Set the topic
        //append the first message if there is no offset
        if (json_messages.links[0].href.match('offset=[1-9]'))
          return;
      }

      // fill in template and display the message
      fill_in_message_template(msg, prev_msg).appendTo(messages);
      prev_msg = msg;

    });
    // Scroll down to the last message
    messages.parent().scrollTop(messages.height());
  } // end function list_talk_messages_from_json

  /**
   * Stop polling for new messages from previous talk.
   */
  function stop_polling() {
    if (window.new_messages_interval_id) {
      window.clearInterval(window.new_messages_interval_id);
    }
  }

  /**
   * Start polling for new messages from the buddy
   */
  function start_polling() {
    stop_polling();
    window.new_messages_interval_id =
      window.setInterval(function() {
        get_new_messages($('#message_form').get(0));
      }, 5000);
  }

  /**
   * Prepares the HTML for the message and returns it.
   * @param msg {Object} The object containig the message
   * @param prev_msg {Obbject} The previous message in the talk.
   * @return {jQuery} The prepared DOM, ready to be appended
   */
  function fill_in_message_template(msg, prev_msg) {
    // fill in template and display the message
    var template = $($('#message_template').html()); //copy
    template.attr('id', 'msg' + msg.id);
    //just to debug order by
    template.attr('title', 'msg' + msg.id);

    var date =
      typeof(msg.tstamp) === 'object' ?
      msg.tstamp :
      new Date(parseInt(msg.tstamp + '000')); //milliseconds
    template.find('.date').html(date.toLocaleString());
    template.find('.message').html(msg.message);
    if (prev_msg.from_uid == msg.from_uid) {
      template.find('.from_uid_name').html('...');
    } else {
      template.find('.from_uid_name').html(msg.from_uid_name + ':');
    }
    return template;
  } // end function fill_in_message_template(msg){

  /**
   * Sets the current talk title and hidden fields in the message form
   * @param {Object} - The message (stub) used to populate the form
   * @return void
   */
  function set_talk_form(msg) {
    if (msg.subject_message_id !== 0) {
      //alert('subject_message_id!=0');
      return false;
    }

    $('#talk_topic').html(
      (msg.subject ? msg.subject : msg.message.substring(0, 30) + '...'));
    $('#talk_topic').attr('title', msg.message);
    var fields = ['to_guid', 'subject', 'message_assets'];
    $.each(fields, function(i, k) {
      $('#message_form [name="' + k + '"]').val(msg[k]);
    });
    var uid = $('#message_form [name="from_uid"]').val();
    $('#message_form [name="to_uid"]').val(
      // to_uid points to the other participant in the talk
      uid == msg.to_uid ? msg.from_uid : msg.to_uid);
    $('#message_form [name="subject_message_id"]').val(msg.id);
  } // end function set_talk(msg)

  /**
   * Starts a new talk with a contact.
   * @return false
   */
  function new_talk() {
    $('#messages .ui.list p').remove(); //empty messages list
    set_talk_form({
      id: 0, // this will be the value of subject_message_id in the form
      subject: '',
      message: '',
      subject_message_id: 0,
      to_uid: $(this).data('id'),
      to_guid: 0
    });
    $('#contacts').sidebar('toggle');
    $('#message_form [name="message"]').focus();
    return false;
  } //end function new_talk()

  // Functionality related to messages
  /**
   * Validates the message form and sends the message.
   * @param {Event} e  Event passed by the binding
   * @return false
   */
  function validate_and_send_message(e) {
    var form = e.target;
    var message_field = $('.field', form);

    message_field.removeClass('error');
    if (form.message.value === '') {
      message_field.addClass('error');
      $(form.message).attr('placeholder', 'PLease write your message!');
      return false;
    }
    //create a new talk from message if needed
    if (form.subject.value === '') {
      form.subject.value = form.message.value;
    }
    // See http://api.jquery.com/jQuery.post/
    $.post(
      form.action,
      $(form).serialize(),
      post_message_success
    ).fail(function(data) {
      //TODO: replace the alert with a beautiful SemanticUI popup or box
      alert('error:' + data.responseText);
      message_field.addClass('error');
      //console.log(data);
    });
    return false;
  } // end function validate_message(e){

  /**
   * Prepares and inserts the message in the #messages box.
   * Executed upon succes of a sent message.
   * @param {Object} data the JSON returned by the server.
   */
  function post_message_success(data) {
    // Prepare the sent message to be appended to the list of messages.
    var form = $('#message_form').get(0);
    var msg = {
      from_uid_name: window.user.name,//from screen action
      tstamp: new Date(),
      id: '0'
    };
    $.each(form, function(i) {
      msg[form[i].name] = form[i].value;
    });
    var last_i = VestTalk.json_messages.data.length - 1;
    var prev_msg = VestTalk.json_messages.data[last_i] || {};
    var messages = $('#messages .ui.list');
    // fill in template and display the message
    fill_in_message_template(msg, prev_msg).appendTo(messages);
    // Scroll down to the last message
    messages.parent().scrollTop(messages.height());
    //clean the textarea and focus it.
    form.message.value = '';
    form.message.focus();
  } // end function post_message_success(data)

  /**
   * Gets new messages from a talk.
   * Similar to get_messages but only gets last 5 messages.
   * @param {obj} form The form object from which we will get everything we need.
   */
  function get_new_messages(form) {
    var url = form.action + '/messages/' + form.subject_message_id.value +
      '.json?limit=5';
    $.get(url, append_messages_from_json, 'json');
  }

  /**
   * Gets new messages from a talk.
   * Similar to list_messages_from_json but only appends messages to the messages box.
   * @param {obj} form The form object from which we will get everything we need.
   */
  function append_messages_from_json(new_json_messages) {
    //remove the local message
    $('#msg0').remove();
    var js_messages = new_json_messages.data;
    var messages = $('#messages .ui.list');
    for (var i in js_messages) {
      var msg = js_messages[i];
      //skip the parent message
      if (msg.subject_message_id === 0) {
        continue;
      }
      //append the new message
      if (document.getElementById('msg' + msg.id) === null) {
        var prev_msg = VestTalk.json_messages.data[VestTalk.json_messages.data.length -
          1];
        // fill in template and display the message
        fill_in_message_template(msg, prev_msg).appendTo(messages);
        VestTalk.json_messages.data.push(msg);
        // Scroll down to the last message
        messages.parent().scrollTop(messages.height());
      }
    } // end for( var i in...
  } //end function append_messages_from_json(new_json_messages)

})(jQuery); //execute